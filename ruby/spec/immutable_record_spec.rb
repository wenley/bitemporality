require 'spec_helper'

RSpec.describe Bitemporal::ImmutableRecord do
  before(:all) do
    ActiveRecord::Base.connection.execute(
      <<-SQL
        DROP TABLE IF EXISTS immutable_addresses
      SQL
    )
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TABLE IF NOT EXISTS immutable_addresses (
          street_1 TEXT
        )
      SQL
    )
  end
  after(:all) do
    ActiveRecord::Base.connection.execute(
      <<-SQL
        DROP TABLE immutable_addresses
      SQL
    )
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'immutable_addresses'
      include Bitemporal::ImmutableRecord
    end
  end

  let(:instance) do
    klass.create!(
      street_1: '1 Infinite Loop',
    )
  end

  context 'updating' do
    it 'fails' do
      expect(instance.update(street_1: 'Anything')).to be_falsey
    end
  end
end
