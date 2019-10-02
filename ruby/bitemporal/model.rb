require_relative './timeline'
require_relative './versioned'

module Bitemporal
  # To be included into
  module Model
    # - - - - - - - - - - - - - - -
    # Configuration
    # - - - - - - - - - - - - - - -

    def self.from_version(transacted_at:, effective_since:, version:)
      raise NotImplementedError, "#{self.name}.from_version"
    end

    def included(api_klass)
      if api_klass <= ActiveRecord::Base
        raise ArgumentError, 'Bitemporal::Model should not be included on ActiveRecord classes'
      end
    end

    def self.version_class(version_class)
      if !(version_class < Versioned)
        raise ArgumentError, 'can only specify a Versioned class'
      end

      @version_class = version_class
    end

    # - - - - - - - - - - - - - - -
    # Single-Instance Operations
    # - - - - - - - - - - - - - - -

    def self.at_time(uuid:, transaction_time:, effective_time:)
      version = query(
        transaction_time: transaction_time,
        effective_time: effective_time,
        inner_query: @version_class.where(uuid: uuid),
      ).first

      from_version(version)
    end

    def self.update_for_range(uuid:, effective_start:, effective_stop:, data:)

    end

    def self.delete_in_range(uuid:, effective_start:, effective_stop:)
      current_time = Time.now
      latest_timeline = Timeline.where(uuid: uuid).at_time(current_time).first

      prior_version = latest_timeline.versions.at_time(effective_start)
      following_version = latest_timeline.versions.at_time(effective_stop)

      versions_to_keep = latest_timeline.versions.select do |version|
        version.effective_stop <= effective_start &&
          version.effective_start >= effective_stop
      end

      if prior_version
        versions_to_keep << @version_class.new(
          prior_version.attributes.merge(
            effective_stop: effective_start,
          ),
        )
      end
      if following_version
        versions_to_keep << @version_class.new(
          following_version.attributes.merge(
            effective_start: effective_stop,
          ),
        )
      end

      Timeline.create!(
        uuid: uuid,
        versions: versions_to_keep,
      )
    end

    # - - - - - - - - - - - - - - -
    # Timeline Operations
    # - - - - - - - - - - - - - - -

    def self.timeline_at(uuid:, transaction_time:)
      timeline = Timeline.
        where(uuid: uuid).
        at_time(transaction_time).
        first

      timeline.versions.order(effective_start: :asc).map do |version|
        from_version(
          transaction_time: timeline.transaction_start,
          effective_since: version.effective_start,
          version: version,
        )
      end
    end

    def self.history_at(uuid:, effective_time:)
      timelines = Timeline.
        where(uuid: uuid).
        joins(:versions).
        merge(@version_class.where(uuid: uuid).at_time(effective_time)).
        order(transaction_start: :asc)

      timelines.map do |timeline|
        version = timeline.versions.at_time(effective_time)

        from_version(
          transaction_time: timeline.transaction_start,
          effective_since: version.effective_start,
          version: version,
        )
      end
    end

    # - - - - - - - - - - - - - - -
    # Bulk Query Operations
    # - - - - - - - - - - - - - - -

    def self.query(transaction_time:, effective_time:, inner_query:)
      timelines =
        case inner_query
        when Proc
          # Recommended; required if making version_class private to callers
          Timeline.
            at_time(transaction_time).
            joins(:versions).
            merge(inner_query.call(@version_class.at_time(effective_time)))

        when ActiveRecord::Relation
          # Not recommended; requires version_class to be public to callers
          Timeline.
            at_time(transaction_time).
            joins(:versions).
            merge(@version_class.at_time(effective_time)).
            merge(inner_query)
        else
          raise ArgumentError, 'inner_query must be a Proc or Relation'
        end

      timelines.map do |timeline|
        version = timeline.versions.at_time(effective_time)

        from_version(
          transaction_time: timeline.transaction_start,
          effective_since: version.effective_start,
          version: version,
        )
      end
    end

    # More powerful API that will return potentially 2-time-dimensional data
    # Callers should be very careful about how they process the data returned
    def self.query_across_time(inner_query:, transaction_time: nil, effective_time: nil)
    end
  end
end
