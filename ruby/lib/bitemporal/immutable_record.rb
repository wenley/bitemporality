
module Bitemporal
  module ImmutableRecord
    def ImmutableRecord.included(active_record_class)
      if !active_record_class.class == Class
        raise ArgumentError, 'Versioned should only be included on classes'
      end
      if !(active_record_class <= ActiveRecord::Base)
        raise ArgumentError, 'Versioned classes should inherit from ActiveRecord::Base'
      end

      active_record_class.class_eval do
        validate :no_changes, on: :update
        validate :no_destroy, on: :destroy
      end
    end

    def no_changes
      if changed?
        errors.add(:base, 'cannot be updated')
      end
    end

    def no_destroy
      throw :abort
    end
  end
end
