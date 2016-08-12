require 'spec_helper'

describe Elastic::Datatypes::Date do
  let(:datatype) do
    described_class.new('dummy', {})
  end

  describe "prepare_for_index" do
    it "validaates that given value is a date or nil" do
      expect { datatype.prepare_for_index(:foo) }.to raise_error ArgumentError
      expect { datatype.prepare_for_index(Time.current) }.to raise_error ArgumentError
      expect { datatype.prepare_for_index(nil) }.not_to raise_error
      expect { datatype.prepare_for_index(Date.current) }.not_to raise_error
    end
  end

  describe "prepare_value_for_result" do
    let(:es_date_str) { '2016-07-14T19:40:27.000-04:00' }
    let(:es_problem_date_str) { '2016-07-14T20:40:27.000-04:00' }
    let(:es_date_long) { 1468525227000 }

    it "transforms string timestamp to date" do
      expect(datatype.prepare_value_for_result(es_date_str)).to eq Date.new(2016, 7, 14)
      expect(datatype.prepare_value_for_result(es_problem_date_str)).to eq Date.new(2016, 7, 15)
    end

    it "transforms long timestamp to date" do
      expect(datatype.prepare_value_for_result(1468525227000)).to eq Date.new(2016, 7, 14)
    end
  end

  describe "supported_aggregations" do
    it "returns an array of hashes" do
      expect(datatype).to support_aggregations(:date_histogram, :terms, :histogram, :range)
    end
  end
end
