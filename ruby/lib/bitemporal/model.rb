require_relative './timeline'
require_relative './versioned'

module Bitemporal
  # To be included into
  module Model
    INFINITY = DateTime.new(3000, 1, 1).freeze

    def Model.included(api_klass)
      if api_klass <= ActiveRecord::Base
        raise ArgumentError, 'Bitemporal::Model should not be included on ActiveRecord classes'
      end

      api_klass.extend(ClassMethods)
    end

    module ClassMethods
      # - - - - - - - - - - - - - - -
      # Configuration
      # - - - - - - - - - - - - - - -

      def from_version(transacted_at:, effective_since:, version:)
        raise NotImplementedError, "#{self.name}.from_version"
      end

      def version_class(version_class)
        if !(version_class < Versioned)
          raise ArgumentError, 'can only specify a Versioned class'
        end

        @version_class = version_class
      end

      # - - - - - - - - - - - - - - -
      # Single-Instance Operations
      # - - - - - - - - - - - - - - -

      def at_time(uuid:, transaction_time:, effective_time:)
        query(
          transaction_time: transaction_time,
          effective_time: effective_time,
          inner_query: @version_class.where(uuid: uuid),
        ).first
      end

      def version_at_time(versions, effective_time)
        versions.find do |version|
          version.effective_start <= effective_time &&
            effective_time < version.effective_stop
        end
      end

      def update_for_range(uuid:, effective_start:, effective_stop:, data:)
        current_time = Time.now
        latest_timeline = Timeline.where(uuid: uuid).at_time(current_time).first

        if latest_timeline.nil?
          versions_to_keep = []
        else
          prior_version = version_at_time(latest_timeline.versions, effective_start)
          following_version = version_at_time(latest_timeline.versions, effective_stop)

          versions_to_keep = latest_timeline.versions.select do |version|
            version.effective_stop <= effective_start ||
              version.effective_start >= effective_stop
          end
          # Fill the time gap
          if prior_version
            versions_to_keep << @version_class.new(
              prior_version.attributes.reject { |k, _| k == 'id' }.merge(
                effective_stop: effective_start,
              ),
            )
          end
          if following_version
            versions_to_keep << @version_class.new(
              following_version.attributes.reject { |k, _| k == 'id' }.merge(
                effective_start: effective_stop,
              ),
            )
          end
        end

        versions_to_keep << @version_class.new(data.merge(
          uuid: uuid,
          effective_start: effective_start,
          effective_stop: effective_stop,
        ))

        Timeline.transaction do
          latest_timeline&.update_columns(transaction_stop: current_time)
          Timeline.create!(
            uuid: uuid,
            timeline_events: versions_to_keep.map { |v| TimelineEvent.new(version: v) },
            transaction_start: current_time,
            transaction_stop: INFINITY,
          )
        end
      end

      def delete_in_range(uuid:, effective_start:, effective_stop:)
        current_time = Time.now
        latest_timeline = Timeline.where(uuid: uuid).at_time(current_time).first

        return unless latest_timeline

        prior_version = version_at_time(latest_timeline.versions, effective_start)
        following_version = version_at_time(latest_timeline.versions, effective_stop)

        versions_to_keep = latest_timeline.versions.select do |version|
          version.effective_stop <= effective_start &&
            version.effective_start >= effective_stop
        end

        if prior_version
          versions_to_keep << @version_class.new(
            prior_version.attributes.reject { |k, _| k == 'id' }.merge(
              effective_stop: effective_start,
            ),
          )
        end
        if following_version
          versions_to_keep << @version_class.new(
            following_version.attributes.reject { |k, _| k == 'id' }.merge(
              effective_start: effective_stop,
            ),
          )
        end

        Timeline.transaction do
          latest_timeline.update!(transaction_stop: current_time)
          Timeline.create!(
            uuid: uuid,
            versions: versions_to_keep,
          )
        end
      end

      # - - - - - - - - - - - - - - -
      # Timeline Operations
      # - - - - - - - - - - - - - - -

      def timeline_at(uuid:, transaction_time:)
        timeline = Timeline.
          where(uuid: uuid).
          at_time(transaction_time).
          first

        timeline.versions.sort_by(&:effective_start).map do |version|
          from_version(
            transacted_at: timeline.transaction_start,
            effective_since: version.effective_start,
            version: version,
          )
        end
      end

      def history_at(uuid:, effective_time:)
        timelines = Timeline.
          where(uuid: uuid).
          joins(:timeline_events).
          joins("INNER JOIN #{@version_class.table_name} ON timeline_events.version_id = #{@version_class.table_name}.id AND timeline_events.version_type = '#{@version_class.name}'").
          merge(@version_class.where(uuid: uuid).at_time(effective_time)).
          order(transaction_start: :asc)

        timelines.map do |timeline|
          # This is inefficient!
          version = version_at_time(timeline.versions, effective_time)

          from_version(
            transacted_at: timeline.transaction_start,
            effective_since: version.effective_start,
            version: version,
          )
        end
      end

      # - - - - - - - - - - - - - - -
      # Bulk Query Operations
      # - - - - - - - - - - - - - - -

      def query(transaction_time:, effective_time:, inner_query:)
        timelines =
          case inner_query
          when Proc
            # Recommended; required if making version_class private to callers
            Timeline.
              at_time(transaction_time).
              joins(:timeline_events).
              joins("INNER JOIN #{@version_class.table_name} ON timeline_events.version_id = #{@version_class.table_name}.id AND timeline_events.version_type = '#{@version_class.name}'").
              merge(inner_query.call(@version_class.at_time(effective_time)))

          when ActiveRecord::Relation
            # Not recommended; requires version_class to be public to callers
            Timeline.
              at_time(transaction_time).
              joins(:timeline_events).
              joins("INNER JOIN #{@version_class.table_name} ON timeline_events.version_id = #{@version_class.table_name}.id AND timeline_events.version_type = '#{@version_class.name}'").
              merge(@version_class.at_time(effective_time)).
              merge(inner_query)
          else
            raise ArgumentError, 'inner_query must be a Proc or Relation'
          end

        timelines.map do |timeline|
          version = version_at_time(timeline.versions, effective_time)

          from_version(
            transacted_at: timeline.transaction_start,
            effective_since: version.effective_start,
            version: version,
          )
        end
      end

      # More powerful API that will return potentially 2-time-dimensional data
      # Callers should be very careful about how they process the data returned
      def query_across_time(inner_query:, transaction_time: nil, effective_time: nil)
      end
    end
  end
end
