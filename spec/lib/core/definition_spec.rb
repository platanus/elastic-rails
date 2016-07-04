require 'spec_helper'

describe Elastic::Core::Definition do
  let(:simple_target) { Class.new.new }

  def build_definition(_target = nil)
    described_class.new().tap do |definition|
      definition.targets = [_target || simple_target]
    end
  end

  def field_double(_name, _mapping = {}, _mapping_inference = true)
    double(:field).tap do |field|
      allow(field).to receive(:name).and_return _name.to_s
      allow(field).to receive(:expanded_names).and_return [_name.to_s]
      allow(field).to receive(:mapping_inference_enabled?).and_return _mapping_inference
      allow(field).to receive(:mapping_options).and_return _mapping
      allow(field).to receive(:has_field?).and_return false
      allow(field).to receive(:get_field).and_return nil
      allow(field).to receive(:freeze).and_return nil
    end
  end

  let(:definition) { build_definition }

  describe "targets" do
    it { expect(definition.targets).to eq [simple_target] }
  end

  describe "main_target" do
    it { expect(definition.main_target).to eq simple_target }
  end

  describe "fields" do
    it { expect(definition.fields).to be_a Enumerator }
    it { expect(definition.fields.count).to eq 0 }
  end

  describe "has_field?" do
    it { expect(definition.has_field? 'foo').to be false }
  end

  describe "get_field" do
    it { expect(definition.get_field 'foo').to be nil }
  end

  describe "as_es_mapping" do
    it { expect(definition.as_es_mapping).to eq({ "properties" => {} }) }
  end

  describe "register_field" do
    # nothing to check here...
  end

  describe "frozen?" do
    it { expect(definition.frozen?).to be false }
  end

  context "definition has been frozen" do
    before { definition.freeze }

    describe "register_field" do
      it { expect { definition.register_field field_double(:foo) }.to raise_error RuntimeError }
    end

    describe "frozen?" do
      it { expect(definition.frozen?).to be true }
    end
  end

  context "fields have been registered" do
    let(:foo_field) { field_double(:foo, { type: 'string' }) }
    let(:bar_field) { field_double(:bar, { type: 'integer' }, false) }

    before do
      definition.register_field foo_field
      definition.register_field bar_field
    end

    describe "fields" do
      it { expect(definition.fields.to_a).to eq [foo_field, bar_field] }
    end

    describe "get_field" do
      it { expect(definition.get_field('foo')).to eq foo_field }

      it "calls field's get_field if nested field is provided" do
        definition.get_field('foo.qux')
        expect(foo_field).to have_received(:get_field).with('qux')
      end
    end

    describe "has_field?" do
      it { expect(definition.has_field?('foo')).to be true }
      it { expect(definition.has_field?('baz')).to be false }
    end

    describe "as_es_mapping" do
      it "calls field's mapping_options" do
        definition.as_es_mapping
        expect(foo_field).to have_received(:mapping_options)
        expect(bar_field).to have_received(:mapping_options)
      end

      it "properly renders mapping" do
        expect(definition.as_es_mapping).to eq({
          'properties' => {
            'foo' => { 'type' => 'string' },
            'bar' => { 'type' => 'integer' }
          }
        })
      end
    end

    describe "expanded_field_names" do
      it "calls registered fields 'expanded_names' method" do
        definition.expanded_field_names
        expect(foo_field).to have_received(:expanded_names)
        expect(bar_field).to have_received(:expanded_names)
      end

      it "returns an array of names" do
        expect(definition.expanded_field_names).to eq ['foo', 'bar']
      end
    end

    describe "freeze" do
      it "calls registered fields 'freeze' method" do
        definition.freeze
        expect(foo_field).to have_received(:freeze)
        expect(bar_field).to have_received(:freeze)
      end
    end
  end

  context "field with no type and mapping inference enabled" do
    let(:foo_field) { field_double(:foo, {}, true) }

    before do
      definition.register_field foo_field
      allow_any_instance_of(Elastic::Commands::InferFieldOptions)
        .to receive(:perform).and_return({ 'type' => 'teapot' })
    end

    describe "as_es_mapping" do
      it "call's field's mapping_inference_enabled?" do
        definition.as_es_mapping
        expect(foo_field).to have_received(:mapping_inference_enabled?)
      end

      it "infers field options from using InferFieldOptions command" do
        expect(definition.as_es_mapping).to eq({
          'properties' => {
            'foo' => { 'type' => 'teapot' }
          }
        })
      end
    end
  end

  context "field with no type and mapping inference disabled" do
    before { definition.register_field field_double(:foo, {}, false) }

    describe "as_es_mapping" do
      it { expect { definition.as_es_mapping }.to raise_error RuntimeError }
    end
  end
end