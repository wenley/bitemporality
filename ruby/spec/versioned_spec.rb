require 'spec_helper'

RSpec.describe Bitemporal::Versioned do
  before(:all) do
    make_sqlite_database
    ActiveRecord::Base.connection.execute(
      <<-SQL
        DROP TABLE IF EXISTS immutable_addresses;
      SQL
    )
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE TABLE IF NOT EXISTS immutable_addresses (
          uuid string NOT NULL,
          effective_start datetime NOT NULL,
          effective_stop datetime NOT NULL,
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

  after do
    ActiveRecord::Base.connection.execute(
      <<-SQL
        DELETE FROM immutable_addresses
      SQL
    )
  end

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'immutable_addresses'
      include Bitemporal::Versioned
    end
  end

  let(:uuid) { '123456' }

  context '.at_time' do
    let!(:instance) do
      klass.create!(
        street_1: '1 Infinite Loop',
        effective_start: effective_start,
        effective_stop: effective_stop,
        uuid: uuid,
      )
    end
    let(:effective_start) { DateTime.new(2019, 1, 1) }
    let(:effective_stop) { DateTime.new(2019, 2, 1) }

    subject { klass.at_time(query_time) }

    context 'before window' do
      let(:query_time) { effective_start - 1.day }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end

    context 'after window' do
      let(:query_time) { effective_stop + 1.day }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end

    context 'middle of window' do
      let(:query_time) { effective_start + 1.day }

      it 'returns the record' do
        expect(subject.count).to eq(1)
      end
    end

    context 'querying at window start' do
      let(:query_time) { effective_start }

      it 'returns the record' do
        expect(subject.count).to eq(1)
      end
    end

    context 'querying at window stop' do
      let(:query_time) { effective_stop }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end
  end
end
