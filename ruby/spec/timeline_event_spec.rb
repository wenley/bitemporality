require 'spec_helper'
require 'support/spec_tables'

RSpec.describe Bitemporal::TimelineEvent do
  before(:all) do
    SpecTables.create_timelines_table
    SpecTables.create_timeline_events_table
  end
  after(:all) do
    SpecTables.drop_table('timeline_events')
    SpecTables.drop_table('timelines')
  end

  let(:uuid) { '123456' }

  describe 'validations' do
    subject(:instance) { described_class.create(timeline: timeline) }
    let(:timeline) { Bitemporal::Timeline.create(uuid: uuid, transaction_start: DateTime.new(2019, 1, 1), transaction_stop: DateTime.new(2019, 2, 1)) }

    it { is_expected.to be_valid }

    context 'without a timeline' do
      let(:timeline) { nil }

      it { is_expected.to_not be_valid }
    end

    describe 'immutability' do
      context 'updating' do
        subject { instance.update!(timeline: nil) }

        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
      end

      context 'destroying' do
        subject { instance.destroy }

        it 'fails to destroy' do
          expect { subject }.to_not change(described_class, :count)
        end
      end
    end
  end
end
