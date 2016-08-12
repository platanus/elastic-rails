require 'spec_helper'

describe Elastic::Datatypes::Time do
  let(:datatype) do
    described_class.new('dummy', { type: 'time' })
  end

  describe "mapping_options" do
    it "replaces 'time' type by 'date'" do
      expect(datatype.mapping_options).to eq(type: 'date')
    end
  end

  describe "prepare_value_for_result" do
    let(:es_date_str) { '2016-07-14T19:40:00.000-04:00' }
    let(:es_date_long) { 1468539600000 }

    it "parses string and long timestamps" do
      expect(datatype.prepare_value_for_result(es_date_str)).to eq Time.new(2016, 7, 14, 19, 40)
      expect(datatype.prepare_value_for_result(es_date_long)).to eq Time.new(2016, 7, 14, 19, 40)
    end
  end

  describe "supported_aggregations" do
    it "returns an array of hashes" do
      expect(datatype).to support_aggregations(:date_histogram, :terms, :histogram, :range)
    end
  end
end
