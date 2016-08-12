require 'spec_helper'

describe Elastic::Fields::Value do
  let(:datatype) do
    double('Datatype').tap do |d|
      allow(d).to receive(:mapping_options).and_return :foo
      allow(d).to receive(:prepare_for_index) { |v| v + ' bar' }
      allow(d).to receive(:prepare_for_query) { |v| v + ' baz' }
      allow(d).to receive(:prepare_value_for_result) { |v| v + ' qux' }
      allow(d).to receive(:supported_aggregations).and_return(
        [{ type: 'terms' }, { type: 'histogram', interval: 10 }, { type: 'foo' }]
      )
    end
  end

  let(:factory) do
    double('DatatypeFactory').tap do |d|
      allow(d).to receive(:new).and_return datatype
    end
  end

  let(:field) { described_class.new('foo', type: factory) }
  let(:field_w_transform) { described_class.new('foo', type: factory, transform: :strip) }

  describe "name" do
    it { expect(described_class.new('foo', {}).name).to eq('foo') }
    it { expect(described_class.new(:foo, {}).name).to eq('foo') }
  end

  describe "needs_inference?" do
    it { expect(field.needs_inference?).to be false }
  end

  describe "validate" do
    it { expect(field.validate).to be nil }
  end

  context "field options do not include type" do
    let(:field) { described_class.new('foo', {}) }
    let(:field_w_transform) { described_class.new('foo', transform: :to_s) }

    describe "validate" do
      it { expect(field.validate).to be_a String }
    end

    describe "needs_inference?" do
      it { expect(field.needs_inference?).to be true }
      it { expect(field_w_transform.needs_inference?).to be false }

      context "disable_mapping_inference has been called" do
        before { field.disable_mapping_inference }

        it { expect(field.needs_inference?).to be false }
      end
    end
  end

  context "frozen field" do
    before do
      field.freeze
      field_w_transform.freeze
    end

    describe "mapping_options" do
      it { expect(field).to forward(:mapping_options, to: datatype) }
    end

    describe "prepare_value_for_index" do
      it "calls datatype prepare_for_index" do
        expect(datatype).to receive(:prepare_for_index).with 'hello'
        expect(field.prepare_value_for_index('hello')).to eq 'hello bar'
      end

      it "calls transform before datatype method if provided" do
        expect(datatype).to receive(:prepare_for_index).with 'hello'
        expect(field_w_transform.prepare_value_for_index(' hello   ')).to eq 'hello bar'
      end
    end

    describe "prepare_value_for_query" do
      it "calls datatype prepare_for_query" do
        expect(datatype).to receive(:prepare_for_query).with 'hello'
        expect(field.prepare_value_for_query('hello')).to eq 'hello baz'
      end

      it "calls transform before datatype method if provided" do
        expect(datatype).to receive(:prepare_for_query).with 'hello'
        expect(field_w_transform.prepare_value_for_query(' hello   ')).to eq 'hello baz'
      end
    end

    describe "prepare_value_for_result" do
      it { expect(field).to forward(:prepare_value_for_result, to: datatype) }
    end

    describe "supported_queries" do
      it { expect(field).to forward(:supported_queries, to: datatype) }
    end

    describe "default_options" do
      it { expect(field).to forward(:term_query_defaults, to: datatype) }
      it { expect(field).to forward(:range_query_defaults, to: datatype) }
      it { expect(field).to forward(:match_query_defaults, to: datatype) }
      it { expect(field).to forward(:terms_aggregation_defaults, to: datatype) }
      it { expect(field).to forward(:date_histogram_aggregation_defaults, to: datatype) }
      it { expect(field).to forward(:histogram_aggregation_defaults, to: datatype) }
      it { expect(field).to forward(:range_aggregation_defaults, to: datatype) }
    end
  end
end
