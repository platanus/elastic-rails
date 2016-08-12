require 'spec_helper'

describe Elastic::Datatypes::Default do
  let(:datatype) do
    described_class.new('dummy', type: 'foo', boost: 'bar', invalid: 'quz')
  end

  describe "mapping_options" do
    it "only filters out invalid es options" do
      expect(datatype.mapping_options).to eq(type: 'foo', boost: 'bar')
    end
  end

  describe "prepare_for_query" do
    it "calls prepare_for_index" do
      expect(datatype).to receive(:prepare_for_index).with(:foo).and_return(:bar)
      expect(datatype.prepare_for_query(:foo)).to eq(:bar)
    end
  end

  describe "prepare_for_index" do
    it "does nothing" do
      expect(datatype.prepare_for_index(:foo)).to eq(:foo)
    end
  end

  describe "prepare_value_for_result" do
    it "does nothing" do
      expect(datatype.prepare_value_for_result(:foo)).to eq(:foo)
    end
  end

  describe "supported_aggregations" do
    it "returns an array of hashes" do
      expect(datatype).to support_aggregations(:terms, :histogram, :range)
    end
  end
end
