require_relative '../velocity'

describe Velocity do
  describe '#*' do
    it 'computes correctly' do
      new_velocity = Velocity.new(2.0, 3.0) * 4
      expect(new_velocity.angle).to eq 2.0
      expect(new_velocity.speed).to eq 12.0
    end
  end

  describe '#+' do
    context 'when combining with point' do
      subject { velocity + point }
      let(:point) { Point.new(0.0, 0.0) }

      context 'when moving east' do
        let(:velocity) { Velocity.new(Math::PI, 1.0) }

        it 'computes correctly' do
          expect(subject.x).to eq -1.0
          expect(subject.y).to be_within(0.01).of(0.0)
        end
      end

      context 'when moving west' do
        let(:velocity) { Velocity.new(0, 1.0) }

        it 'computes correctly' do
          expect(subject.x).to eq 1.0
          expect(subject.y).to be_within(0.01).of(0.0)
        end
      end

      context 'when moving north' do
        let(:velocity) { Velocity.new(Math::PI / 2, 1.0) }

        it 'computes correctly' do
          expect(subject.x).to be_within(0.01).of(0.0)
          expect(subject.y).to eq 1.0
        end
      end

      context 'when moving south' do
        let(:velocity) { Velocity.new(3 * Math::PI / 2, 1.0) }

        it 'computes correctly' do
          expect(subject.x).to be_within(0.01).of(0.0)
          expect(subject.y).to eq -1.0
        end
      end

      context 'when moving southeast' do
        let(:velocity) { Velocity.new(5 * Math::PI / 4, Math.sqrt(2.0)) }

        it 'computes correctly' do
          expect(subject.x).to be_within(0.001).of(-1.0)
          expect(subject.y).to eq -1.0
        end
      end

      context 'when moving southwest' do
        let(:velocity) { Velocity.new(7 * Math::PI / 4, Math.sqrt(2.0)) }

        it 'computes correctly' do
          expect(subject.x).to eq 1.0
          expect(subject.y).to be_within(0.01).of(-1.0)
        end
      end

      context 'when moving northeast' do
        let(:velocity) { Velocity.new(3 * Math::PI / 4, Math.sqrt(2.0)) }

        it 'computes correctly' do
          expect(subject.x).to eq -1.0
          expect(subject.y).to be_within(0.01).of(1.0)
        end
      end

      context 'when moving northwest' do
        let(:velocity) { Velocity.new(Math::PI / 4, Math.sqrt(2.0)) }

        it 'computes correctly' do
          expect(subject.x).to be_within(0.01).of(1.0)
          expect(subject.y).to eq 1.0
        end
      end
    end
  end
end
