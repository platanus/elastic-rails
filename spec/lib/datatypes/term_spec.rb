require 'spec_helper'

describe Elastic::Datatypes::Term do
  let(:datatype) do
    described_class.new('dummy', type: 'foo')
  end

  describe "mapping_options" do
    it "sets special term options" do
      expect(datatype.mapping_options).to eq(type: 'string', index: 'not_analyzed')
    end
  end

  describe "supported_aggregations" do
    it "returns an array of hashes" do
      expect(datatype).to support_aggregations(:terms, :histogram, :range)
    end
  end
end
