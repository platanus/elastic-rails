require 'spec_helper'

describe Elastic::Core::Serializer do
  let(:foo_field) { Elastic::Fields::Value.new('foo', {}) }
  let(:bar_field) { Elastic::Fields::Value.new('bar', {}) }

  let(:definition) { definition_double(fields: [foo_field, bar_field]) }

  let(:serializer) do
    Class.new(described_class) do
    end
  end

  let(:serializer_w_override) do
    Class.new(described_class) do
      def foo
        object.foo + ' rules!'
      end
    end
  end

  describe "self.original_value_occluded?" do
    it "returns true if there is an overriden attribute" do
      expect(serializer.original_value_occluded?(:foo)).to be false
      expect(serializer_w_override.original_value_occluded?(:foo)).to be true
      expect(serializer_w_override.original_value_occluded?(:bar)).to be false
    end
  end

  describe "as_es_document" do
    it "only serializes properties added to the definition as fields" do
      object = OpenStruct.new(foo: 'foo', bar: 'bar', qux: true)
      expect(serializer.new(definition, object).as_es_document)
        .to eq({ 'foo' => 'foo', 'bar' => 'bar' })
    end

    it "calls each field 'prepare_value_for_index' method" do
      object = OpenStruct.new(foo: 'foo', bar: 'bar')
      expect(foo_field).to receive(:prepare_value_for_index).with('foo')
      expect(bar_field).to receive(:prepare_value_for_index).with('bar')
      serializer.new(definition, object).as_es_document
    end

    it "properly handles overriden attributes" do
      object = OpenStruct.new(foo: 'foo', bar: 'bar')
      expect(serializer_w_override.new(definition, object).as_es_document)
        .to eq({ 'foo' => 'foo rules!', 'bar' => 'bar' })
    end
  end
end