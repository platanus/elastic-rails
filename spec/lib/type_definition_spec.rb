require 'spec_helper'

describe Elastic::TypeDefinition do

  let(:default_name) { 'default-name' }
  let(:simple_target) { Class.new.new }

  def build_definition(_target = nil)
    described_class.new(default_name, _target || simple_target)
  end

  let(:definition) { build_definition }

  describe "name" do
    it { expect(definition.name).to eq default_name }
    it { expect { definition.name = 'foo' }.to change { definition.name }.to 'foo' }
  end

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

  describe "get_field_type" do
    it { expect(definition.get_field_type 'foo').to be nil }
  end

  describe "prepare_field_for_query" do
    it { expect(definition.prepare_field_for_query('foo', 'bar')).to eq 'bar' }
  end

  describe "register_field" do
    # nothing to check here...
  end

  context "given some fields have been registered" do
    before do
      definition.register_field(:foo, { type: :string })
      definition.register_field('bar', { type: :term })
      definition.register_field('baz', { type: :term, transform: -> { self + 1 } })
      definition.register_field('qux', { type: :term, transform: :floor })
    end

    describe "fields" do
      it { expect(definition.fields.to_a).to eq ['foo', 'bar', 'baz', 'qux'] }
    end

    describe "has_field?" do
      it { expect(definition.has_field?('foo')).to be true }
      it { expect(definition.has_field?('baz')).to be true }
    end

    describe "get_field_type" do
      it { expect(definition.get_field_type('foo')).to eq :string }
      it { expect(definition.get_field_type('baz')).to eq :term }
    end

    describe "prepare_field_for_query" do
      it { expect(definition.prepare_field_for_query('foo', 1)).to eq 1 }
      it { expect(definition.prepare_field_for_query('baz', 1)).to eq 2 }
      it { expect(definition.prepare_field_for_query('qux', 1.1)).to eq 1 }
    end
  end

  context "given an active record like target" do
    let(:ar_target) do
      Class.new do
        def self.columns_hash
          {
            'string' => OpenStruct.new({ type: :string }),
            'integer' => OpenStruct.new({ type: :integer })
          }
        end
      end
    end

    let(:definition) { build_definition(ar_target) }

    before do
      definition.register_field(:string)
      definition.register_field(:integer)
    end

    describe "get_field_type" do
      it { expect(definition.get_field_type('string')).to eq :string }
      it { expect(definition.get_field_type('integer')).to eq :long }
    end
  end
end