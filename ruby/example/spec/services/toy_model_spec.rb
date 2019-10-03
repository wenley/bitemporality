require 'rails_helper'

describe ToyModel do
  let(:uuid) { '123456' }

  describe '.at_time' do
    subject { described_class.at_time(uuid: uuid, transaction_time: transaction_time, effective_time: effective_time) }
    let(:transaction_time) { DateTime.new(2019, 1, 1) }
    let(:effective_time) { DateTime.new(2019, 1, 1) }

    context 'no existing timeline' do
      it { is_expected.to eq(nil) }
    end

    context 'one existing timeline' do
      let!(:timeline) do
        Bitemporal::Timeline.create!(
          uuid: uuid,
          transaction_start: transaction_start,
          transaction_stop: transaction_stop,
          timeline_events: [Bitemporal::TimelineEvent.new(version: version)],
        )
      end

      let(:version) { ToyVersion.new(uuid: uuid, effective_start: version_start, effective_stop: version_stop) }
      let(:version_start) { effective_time - 1.day }
      let(:version_stop) { effective_time + 1.day }
      let(:transaction_start) { transaction_time - 1.day }
      let(:transaction_stop) { transaction_time + 1.day }

      context 'straddling in both transaction_time and effective_time' do
        it { is_expected.to_not eq(nil) }
      end

      context 'too early timeline' do
        let(:transaction_stop) { transaction_time - 1.hour }
        it { is_expected.to eq(nil) }
      end

      context 'too late timeline' do
        let(:transaction_start) { transaction_time + 1.hour }
        it { is_expected.to eq(nil) }
      end

      context 'too early version' do
        let(:version_stop) { effective_time - 1.hour }
        it { is_expected.to eq(nil) }
      end

      context 'too late version' do
        let(:version_start) { effective_time + 1.hour }
        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '.update_for_range' do
    subject { described_class.update_for_range(uuid: uuid, effective_start: effective_start, effective_stop: effective_stop, data: {}) }
    let(:effective_start) { DateTime.new(2019, 1, 1) }
    let(:effective_stop) { DateTime.new(2019, 2, 1) }
    let(:fake_now) { DateTime.new(2019, 7, 1) }

    before do
      Timecop.freeze(fake_now)
    end

    context 'no existing timeline' do
      it 'makes a new Timeline' do
        expect { subject }.to change(Bitemporal::Timeline, :count).by(1)
      end

      it 'makes a new Version' do
        expect { subject }.to change(ToyVersion, :count).by(1)
      end

      it 'sets the proper transaction range' do
        expect(subject.transaction_start).to eq(fake_now)
        expect(subject.transaction_stop).to eq(Bitemporal::Model::INFINITY)
      end
    end

    context 'with existing timeline' do
      let!(:timeline) do
        Bitemporal::Timeline.create!(
          uuid: uuid,
          transaction_start: existing_transaction_start,
          transaction_stop: existing_transaction_stop,
          timeline_events: events,
        )
      end
      let(:events) { versions.map { |version| Bitemporal::TimelineEvent.new(version: version) } }
      let(:versions) { [] }
      let(:existing_transaction_start) { DateTime.new(2019, 1, 1) }
      let(:existing_transaction_stop) { Bitemporal::Model::INFINITY }

      let(:versions) { [old_version] }
      let(:old_version) do
        ToyVersion.create!(
          uuid: uuid,
          effective_start: start,
          effective_stop: stop,
        )
      end
      let(:start) { effective_start + 1.minute }
      let(:stop) { effective_stop - 1.minute }

      it 'marks prior timeline stop' do
        expect { subject }.to change {
          timeline.reload.transaction_stop
        }.from(existing_transaction_stop).to(fake_now)
      end

      describe 'effective range collisions' do
        context 'non-overlapping version' do
          let(:start) { stop - 1.day }
          let(:stop) { effective_start - 1.day }

          it 'reuses existing versions' do
            expect(subject.versions).to include(old_version)
          end
        end

        context 'total overlap' do
          it 'omits the old version' do
            expect(subject.versions.count).to eq(1)
            version = subject.versions.first
            expect(version.effective_start).to eq(effective_start)
            expect(version.effective_stop).to eq(effective_stop)
          end
        end

        context 'overlap on front of desired range' do
          let(:start) { effective_start - 1.day }
          let(:stop) { effective_start + 1.day }

          it 'makes a new version with updated stop' do
            expect(subject.versions.count).to eq(2)
            updated_version = subject.versions.find { |v| v.effective_start == start }
            expect(updated_version.effective_stop).to eq(effective_start)
          end
        end

        context 'overlap on back of desired range' do
          let(:start) { effective_stop - 1.day }
          let(:stop) { effective_stop + 1.day }

          it 'makes a new version with updated start' do
            expect(subject.versions.count).to eq(2)
            updated_version = subject.versions.find { |v| v.effective_stop == stop }
            expect(updated_version.effective_start).to eq(effective_stop)
          end
        end

        context 'new range contained in old range' do
          let(:start) { effective_start - 1.day }
          let(:stop) { effective_stop + 1.day }

          it 'makes two new versions' do
            expect(subject.versions.count).to eq(3)
            new_front = subject.versions.find { |v| v.effective_start == start }
            new_back = subject.versions.find { |v| v.effective_stop == stop }
            expect(new_front.effective_stop).to eq(effective_start)
            expect(new_back.effective_start).to eq(effective_stop)
          end
        end
      end
    end
  end
end
