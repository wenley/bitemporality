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

      active_record_class.instance_eval(ClassMethods)
    end

    module ClassMethods
      def belongs_to_bitemporal(association_name, model:)
        define_method(association_name) do |transaction_time:, effective_time:|
          uuid = send("#{association_name}_uuid")

          model.at_time(uuid: uuid, transaction_time: transaction_time, effective_time: effective_time)
        end
      end

      def has_one_bitemporal(association_name, model:, foreign_key: nil)
        define_method(association_name) do |transaction_time:, effective_time:|
          foreign_key ||= "#{self.name.snakecase}_uuid"

          model.query(
            transaction_time: transaction_time,
            effective_time: effective_time,
            inner_query: ->(relation) { relation.where(foreign_key => self.uuid) },
          ).first
        end
      end

      def has_many_bitemporal(association_name)
        define_method(association_name) do |transaction_time:, effective_time:|
          foreign_key ||= "#{self.name.snakecase}_uuid"

          model.query(
            transaction_time: transaction_time,
            effective_time: effective_time,
            inner_query: ->(relation) { relation.where(foreign_key => self.uuid) },
          )
        end
      end
    end
  end
end
