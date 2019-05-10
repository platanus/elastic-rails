require 'spec_helper'

describe Elastic::Core::Definition do
  let(:simple_target) { build_type('Foo', :id) }
  let(:middleware) { Class.new(Elastic::Core::BaseMiddleware) { def mode; :index end } }
  let(:definition) { described_class.new.tap { |d| d.target = simple_target } }

  before do
    allow(Elastic::Core::Middleware).to receive(:wrap) { |t| middleware.new(t) }
  end

  describe "middleware_options" do
    it "holds key -> value pairs with indifferent access" do
      definition.middleware_options[:foo] = 'bar'
      expect(definition.middleware_options['foo']).to eq 'bar'
    end
  end

  describe "fields" do
    it { expect(definition.fields).to be_a Enumerator }
    it { expect(definition.fields.count).to eq 0 }
  end

  describe "has_field?" do
    it { expect { definition.has_field?('foo') }.to raise_error RuntimeError }
  end

  describe "get_field" do
    it { expect { definition.get_field('foo') }.to raise_error RuntimeError }
  end

  describe "as_es_mapping" do
    it { expect { definition.as_es_mapping }.to raise_error RuntimeError }
  end

  describe "register_field" do
    # nothing to check here...
  end

  describe "frozen?" do
    it { expect(definition.frozen?).to be false }
  end

  context "definition has been frozen" do
    before { definition.freeze }

    describe "target" do
      it "wraps target using middleware provided by Middleware module" do
        expect(definition.target).to be_a middleware
      end
    end

    describe "register_field" do
      it { expect { definition.register_field field_double(:foo) }.to raise_error RuntimeError }
    end

    describe "frozen?" do
      it { expect(definition.frozen?).to be true }
    end

    describe "middleware_options" do
      it "gets frozen" do
        expect(definition.middleware_options.frozen?).to be true
        expect { definition.middleware_options[:foo] = 'bar' }.to raise_error RuntimeError
      end
    end

    describe "has_field?" do
      it { expect(definition.has_field?('foo')).to be false }
    end

    describe "get_field" do
      it { expect(definition.get_field('foo')).to be nil }
    end

    describe "as_es_mapping" do
      it { expect(definition.as_es_mapping).to eq("properties" => {}) }
    end
  end

  context "fields have been registered" do
    let(:foo_field) { field_double(:foo, mapping: { type: 'string' }) }
    let(:bar_field) { field_double(:bar, mapping: { type: 'integer' }) }

    before do
      definition.register_field foo_field
      definition.register_field bar_field
    end

    describe "freeze" do
      it "calls registered fields 'freeze' method" do
        definition.freeze
        expect(foo_field).to have_received(:freeze)
        expect(bar_field).to have_received(:freeze)
      end
    end

    context "and definition has been frozen" do
      before { definition.freeze }

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
          expect(definition.as_es_mapping).to eq(
            'properties' => {
              'foo' => { 'type' => 'string' },
              'bar' => { 'type' => 'integer' }
            }
          )
        end
      end
    end
  end

  context "field with inference enabled" do
    let(:foo_field) { field_double(:foo, inference: true) }

    before do
      allow_any_instance_of(middleware)
        .to receive(:field_options_for)
        .and_return('type' => 'teapot')

      definition.register_field foo_field
    end

    describe "freeze" do
      it "call's field_options_for and field's needs_inference?" do
        definition.freeze
        expect(definition.target).to have_received(:field_options_for).with('foo', {})
        expect(foo_field).to have_received(:needs_inference?)
        expect(foo_field).to have_received(:merge!).with('type' => 'teapot')
      end
    end
  end

  context "field with validation errors" do
    before do
      definition.register_field field_double(:foo, validation_error: 'foo error')
    end

    describe "freeze" do
      it { expect { definition.freeze }.to raise_error RuntimeError }
    end
  end
end
