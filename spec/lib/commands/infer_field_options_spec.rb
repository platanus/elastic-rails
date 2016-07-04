require 'spec_helper'

describe Elastic::Commands::InferFieldOptions do
  let(:target) { Class.new }

  def perform(_field)
    described_class.for klass: target, field: _field
  end

  it "returns nil if target is not recognized" do
    expect(perform('foo')).to be nil
  end

  context "target is an active record 4 model" do
    let(:target) do
      Class.new do
        def self.columns_hash
          {
            'foo' => OpenStruct.new({ type: 'text' }),
            'bar' => OpenStruct.new({ type: 'date' }),
            'baz' => OpenStruct.new({ type: 'date' })
          }
        end

        def self.serialized_attributes
          {
            'bar' => OpenStruct.new()
          }
        end

        def baz
        end
      end
    end

    it "infers type from column type" do
      expect(perform('foo')).to eq({ type: :string })
    end

    it "returns nil if target is occluded by a serializer" do
      expect(perform('bar')).to be nil
    end

    it "returns nil if target is occluded by a method override" do
      expect(perform('baz')).to be nil
    end
  end

  context "target is an active record 5 model" do
    let(:target) do
      Class.new do
        def self.type_for_attribute(_name)
          {
            'foo' => OpenStruct.new({ type: 'text' }),
            'bar' => OpenStruct.new({ to_s: 'ActiveRecord::Type::Serialized' }),
            'baz' => OpenStruct.new({ type: 'date' })
          }
          .fetch(_name, nil)
        end

        def baz
        end
      end
    end

    it "infers type from column type" do
      expect(perform('foo')).to eq({ type: :string })
    end

    it "returns nil if target is occluded by a serializer" do
      expect(perform('bar')).to be nil
    end

    it "returns nil if target is occluded by a method override" do
      expect(perform('baz')).to be nil
    end
  end
end