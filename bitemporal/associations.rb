require 'active_record'

module Bitemporal
  module Associations
    def Associations.included(active_record_class)
      if !active_record_class.class == Class
        raise ArgumentError, 'Bitemporal::Associations should only be directly included on classes'
      end

      if !(active_record_class <= ActiveRecord::Base)
        raise ArgumentError, 'Bitemporal::Associations classes should inherit from ActiveRecord::Base'
      end
    end

    def self.belongs_to_bitemporal(association_name)

    end

    def self.has_one_bitemporal(association_name)

    end

    def self.has_many_bitemporal(association_name)

    end
  end
end
