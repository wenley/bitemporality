require 'active_record'

module Bitemporal
  module Versioned
    REQUIRED_COLUMNS = [:effective_start, :effective_stop, :uuid]

    def Versioned.included(active_record_class)
      if !active_record_class.class == Class
        raise ArgumentError, 'Versioned should only be directly included on classes'
      end

      if !(active_record_class <= ActiveRecord::Base)
        raise ArgumentError, 'Versioned classes should inherit from ActiveRecord::Base'
      end

      missing_columns = REQUIRED_COLUMNS - active_record_class.column_names
      if missing_columns.count != 0
        raise ArgumentError, "Versioned classes must have columns #{REQUIRED_COLUMNS}. #{active_record_class} is missing #{missing_columns}"
      end

      active_record_class.scope :at_time, ->(time) { where('effective_start <= ? AND ? < effective_stop', time, time) }
      active_record_class.include(ImmutableRecord)
    end
  end
end
