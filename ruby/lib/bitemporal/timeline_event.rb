require 'active_record'

module Bitemporal
  class TimelineEvent < ActiveRecord::Base
    include ImmutableRecord

    self.table_name = 'timeline_events'

    belongs_to :timeline
    belongs_to :version, polymorphic: true
  end
end
