require_relative '../player'

describe Player do
  describe '#chase' do
    let(:player_1) { described_class.new(data_1) }
    let(:player_2) { described_class.new(data_2) }
    subject { player_1.chase(player_2) }

    context 'when direction is north' do
      let(:data_1) { { 'x' => 1.0, 'y' => 1.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 2.0 } }

      it { is_expected.to eq (3 * Math::PI / 2) }
    end

    context 'when direction is south' do
      let(:data_1) { { 'x' => 1.0, 'y' => 2.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq (Math::PI / 2) }
    end

    context 'when direction is west' do
      let(:data_1) { { 'x' => 1.0, 'y' => 1.0 } }
      let(:data_2) { { 'x' => 2.0, 'y' => 1.0 } }

      it { is_expected.to eq 0 }
    end

    context 'when direction is east' do
      let(:data_1) { { 'x' => 2.0, 'y' => 1.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq Math::PI }
    end

    context 'when direction is northeast' do
      let(:data_1) { { 'x' => 2.0, 'y' => 2.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq (5 * Math::PI / 4) }
    end

    context 'when direction is northwest' do
      let(:data_1) { { 'x' => 0.0, 'y' => 2.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq (7 * Math::PI / 4) }
    end

    context 'when direction is southwest' do
      let(:data_1) { { 'x' => 0.0, 'y' => 0.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq (Math::PI / 4) }
    end

    context 'when direction is southeast' do
      let(:data_1) { { 'x' => 2.0, 'y' => 0.0 } }
      let(:data_2) { { 'x' => 1.0, 'y' => 1.0 } }

      it { is_expected.to eq (3 * Math::PI / 4) }
    end
  end
end
