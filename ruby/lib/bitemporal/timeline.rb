require 'active_record'
require_relative './immutable_record'
require_relative './timeline_event'

module Bitemporal
  class Timeline < ActiveRecord::Base
    include ImmutableRecord

    has_many :timeline_events, class_name: 'TimelineEvent'
    has_many :versions, through: :timeline_events

    scope :at_time, ->(time) { where('transaction_start <= ? AND ? < transaction_stop', time, time) }

    validates :versions_have_same_uuid
    validates :versions_dont_overlap_effective_ranges

    def versions_have_same_uuid
      uuids = versions.map(&:uuid).uniq

      if uuids.count > 1
        errors.add(:versions, "all must have same UUID vs #{uuids}")
      elsif uuids.count == 1 && uuids.count != uuid
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
