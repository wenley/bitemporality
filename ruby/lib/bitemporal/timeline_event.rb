require 'active_record'

module Bitemporal
  class TimelineEvent < ActiveRecord::Base
    include ImmutableRecord

    belongs_to :timeline
    belongs_to :version, polymorphic: true
  end
end
