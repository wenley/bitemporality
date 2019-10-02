require_relative './timeline'
require_relative './versioned'

module Bitemporal
  # To be included into
  module Model
    # - - - - - - - - - - - - - - -
    # Configuration
    # - - - - - - - - - - - - - - -

    Value = Struct.new(:transacted_at, :effective_since, :value)

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
      query(
        transaction_time: transaction_time,
        effective_time: effective_time,
        inner_query: @version_class.where(uuid: uuid),
      )
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

    end

    def self.history_at(uuid:, effective_time:)

    end

    # - - - - - - - - - - - - - - -
    # Bulk Query Operations
    # - - - - - - - - - - - - - - -
    def self.query(transaction_time:, effective_time:, inner_query:)
      case inner_query
      when Proc
        # Recommended; required if making version_class private to callers
        Timeline.
          at_time(transaction_time).
          merge(inner_query.call(@version_class.at_time(effective_time)))
      when ActiveRecord::Relation
        # Not recommended; requires version_class to be public to callers
        Timeline.
          at_time(transaction_time).
          merge(@version_class.at_time(effective_time)).
          merge(inner_query)
      else
        raise ArgumentError, 'inner_query must be a Proc or Relation'
      end
    end
  end
end
