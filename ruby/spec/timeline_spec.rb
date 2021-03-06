require 'spec_helper'
require 'support/spec_tables'

RSpec.describe Bitemporal::Timeline do
  before(:all) do
    SpecTables.create_timelines_table
  end
  after(:all) do
    SpecTables.drop_table('timelines')
  end
  let(:uuid) { '123456' }

  describe '.at_time' do
    subject { described_class.at_time(query_time) }
    let!(:instance) do
      described_class.create!(
        uuid: uuid,
        transaction_start: transaction_start,
        transaction_stop: transaction_stop,
      )
    end
    let(:transaction_start) { DateTime.new(2019, 1, 1) }
    let(:transaction_stop) { DateTime.new(2019, 2, 1) }

    context 'before window' do
      let(:query_time) { transaction_start - 1.day }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end

    context 'after window' do
      let(:query_time) { transaction_stop + 1.day }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end

    context 'middle of window' do
      let(:query_time) { transaction_start + 1.day }

      it 'returns the record' do
        expect(subject.count).to eq(1)
      end
    end

    context 'querying at window start' do
      let(:query_time) { transaction_start }

      it 'returns the record' do
        expect(subject.count).to eq(1)
      end
    end

    context 'querying at window stop' do
      let(:query_time) { transaction_stop }

      it 'returns nothing' do
        expect(subject.count).to eq(0)
      end
    end
  end

  describe 'validations' do
    # Requires TimelineEvent table
  end
end
