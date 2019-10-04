require 'spec_helper'
require 'support/spec_tables'

RSpec.describe Bitemporal::Timeline do
  before(:all) do
    SpecTables.create_timelines_table
  end
  after(:all) do
    SpecTables.drop_table('timelines')
  end
  let(:uuid) { '123456a' }

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
    before(:all) do
      SpecTables.create_versioned_addresses_table
      SpecTables.create_timeline_events_table
    end
    after(:all) do
      SpecTables.drop_table('timeline_events')
      SpecTables.drop_table('versioned_addresses')
    end

    subject do
      described_class.create!(
        uuid: timeline_uuid,
        timeline_events: timeline_events,
        transaction_start: DateTime.new(2019, 1, 1),
        transaction_stop: DateTime.new(2019, 2, 1),
      )
    end
    let(:timeline_uuid) { uuid }
    let(:timeline_events) { versions.map { |v| Bitemporal::TimelineEvent.new(version: v) } }
    let(:versions) { [version_1, version_2] }

    let!(:versioned_address_class) do
      Object.const_set(
        'VersionedAddress',
        Class.new(ActiveRecord::Base) do
          self.table_name = 'versioned_addresses'
          include Bitemporal::Versioned
        end,
      )

      VersionedAddress
    end
    let(:version_1) do
      versioned_address_class.create!(
        uuid: version_1_uuid,
        effective_start: DateTime.new(2019, 1, 1),
        effective_stop: DateTime.new(2019, 2, 1),
        street_1: '1 Infinity Loop',
      )
    end
    let(:version_2) do
      versioned_address_class.create!(
        uuid: version_2_uuid,
        effective_start: version_2_start,
        effective_stop: DateTime.new(2019, 3, 1),
        street_1: '123 Infinity Loop',
      )
    end

    let(:version_1_uuid) { uuid }
    let(:version_2_uuid) { uuid }
    let(:version_2_start) { version_1.effective_stop }

    it { is_expected.to be_valid }

    context 'mixed version types' do
      let(:timeline_events) do
        [
          Bitemporal::TimelineEvent.new(
            version_id: 1,
            version_type: 'VersionedAddress',
          ),
          Bitemporal::TimelineEvent.new(
            version_id: 2,
            version_type: 'OtherThing',
          ),
        ]
      end

      it { is_expected.to_not be_valid }
    end

    context 'versions have different UUIDs' do
      let(:version_2_uuid) { 'abcdef' }

      it { is_expected.to_not be_valid }
    end

    context 'overlapping ranges' do
      let(:version_2_start) { version_1.effective_stop - 1.day }

      it { is_expected.to_not be_valid }
    end
  end
end
