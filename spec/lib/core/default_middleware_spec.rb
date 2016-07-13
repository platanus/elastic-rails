require 'spec_helper'

describe Elastic::Core::DefaultMiddleware do
  let(:target) { Class.new }
  let(:middleware) { described_class.new(target) }

  describe 'mode' do
    it { expect(middleware.mode).to be :storage }
  end

  describe 'field_options_for' do
    it { expect(middleware.field_options_for(:foo, {})).to be nil }
  end

  describe 'collect_all' do
    it { expect { middleware.collect_all({}) }.not_to raise_error }
  end

  describe 'collect_for' do
    it { expect { middleware.collect_for(nil, {}) }.to raise_error ArgumentError }
    it { expect { middleware.collect_for([], {}) }.not_to raise_error }
  end

  describe 'build_from_data' do
    it { expect(middleware.build_from_data({ foo: 'bar' }, {})).to be_a OpenStruct }
    it { expect(middleware.build_from_data({ foo: 'bar' }, {}).foo).to eq 'bar' }
  end

  context "the target implements 'find_by_elastic_ids'" do
    before { allow(target).to receive(:find_by_elastic_ids).and_return([:foo]) }

    describe 'mode' do
      it { expect(middleware.mode).to be :index }
    end

    describe 'find_by_ids' do
      it "should call 'find_by_elastic_ids'" do
        expect(middleware.find_by_ids([1], {})).to eq [:foo]
        expect(target).to have_received(:find_by_elastic_ids).with([1])
      end
    end
  end

  context "the target implements 'build_from_elastic_data" do
    before { allow(target).to receive(:build_from_elastic_data).and_return(:foo) }

    describe 'mode' do
      it { expect(middleware.mode).to be :storage }
    end

    describe 'build_from_data' do
      it "should call 'build_from_elastic_data'" do
        expect(middleware.build_from_data({}, {})).to eq :foo
        expect(target).to have_received(:build_from_elastic_data).with({})
      end
    end
  end
end
