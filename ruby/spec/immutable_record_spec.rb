require 'spec_helper'

RSpec.describe Bitemporal::ImmutableRecord do
  before do
    make_sqlite_database
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TABLE IF NOT EXISTS immutable_addresses (
          street_1 TEXT
        )
      SQL
    )
  end
  class ImmutableAddress < ActiveRecord::Base
    include Bitemporal::ImmutableRecord
  end

  let(:instance) do
    ImmutableAddress.create!(
      street_1: '1 Infinite Loop',
    )
  end

  context 'updating' do
    it 'fails' do
      expect(instance.update(street_1: 'Anything')).to be_falsey
    end
  end
end
