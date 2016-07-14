require 'spec_helper'

describe Elastic::Fields::Value do
  let(:field) { described_class.new('foo', { type: 'string' }) }
  let(:field_w_transform) { described_class.new('foo', type: 'integer', transform: :to_s) }
  let(:field_w_lambda) { described_class.new('foo', type: 'integer', transform: -> { floor }) }
  let(:term_field) { described_class.new('foo', { type: 'term' }) }
  let(:date_field) { described_class.new('foo', { type: 'date' }) }

  describe "name" do
    it { expect(described_class.new('foo', {}).name).to eq('foo') }
    it { expect(described_class.new(:foo, {}).name).to eq('foo') }
  end

  describe "mapping_inference_enabled?" do
    it { expect(field.mapping_inference_enabled?).to be true }
    it { expect(field_w_transform.mapping_inference_enabled?).to be false }

    context "disable_mapping_inference has been called" do
      before { field.disable_mapping_inference }

      it { expect(field.mapping_inference_enabled?).to be false }
    end
  end

  describe "mapping_options" do
    it "includes only elasticsearch mapping properties" do
      expect(field.mapping_options).to eq({ type: 'string' })
      expect(field_w_transform.mapping_options).to eq({ type: 'integer' })
    end

    it "expands special types" do
      expect(term_field.mapping_options).to eq({ type: 'string', index: 'not_analyzed' })
      expect(date_field.mapping_options).to eq({ type: 'date', format: 'dateOptionalTime' })
    end
  end

  describe "prepare_value_for_index" do
    it { expect(field.prepare_value_for_index(1)).to eq 1 }
    it { expect(field_w_transform.prepare_value_for_index(1)).to eq "1" }
    it { expect(field_w_lambda.prepare_value_for_index(1.9)).to eq 1 }
  end
end