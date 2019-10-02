require 'active_record'
require_relative './immutable_record'
require_relative './timeline_event'

module Bitemporal
  class Timeline < ActiveRecord::Base
    include ImmutableRecord

    self.table_name = 'timelines'

    has_many :timeline_events, class_name: 'TimelineEvent'

    scope :at_time, ->(time) { where('transaction_start <= ? AND ? < transaction_stop', time, time) }

    validate :versions_have_same_uuid
    validate :versions_dont_overlap_effective_ranges
    validate :timeline_events_have_same_version_type

    def versions
      timeline_events.first.version_type.constantize.
        where(id: timeline_events.map(&:version_id))
    end

    def timeline_events_have_same_version_type
      types = timeline_events.map(&:version_type).uniq
      if types.count > 1
        errors.add(:timeline_events, "all must have same version_type vs #{types}")
      end
    end

    def versions_have_same_uuid
      uuids = versions.map(&:uuid).uniq

      if uuids.count > 1
        errors.add(:versions, "all must have same UUID vs #{uuids}")
      elsif uuids.count == 1 && uuids.first != uuid
        errors.add(:versions, "all must have same UUID as Timeline #{uuid}")
      end
    end

    def versions_dont_overlap_effective_ranges
      versions.sort_by(&:effective_start).each_cons(2) do |v1, v2|
        if v2.effective_start < v1.effective_stop
          errors.add(:versions, 'have overlaps in effective_ranges')
        end
      end
    end
  end
end
