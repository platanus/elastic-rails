require 'spec_helper'
require 'elastic/railties/ar_helpers'

describe Elastic::Railties::ARHelpers do
  let(:helpers) { described_class }

  describe "find_each_with_options" do
    pending "handles preload and scope options"
  end

  describe "infer_ar4_field_options" do
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
      expect(helpers.infer_ar4_field_options(target, 'foo')).to eq({ type: :string })
    end

    it "returns nil if target is occluded by a serializer" do
      expect(helpers.infer_ar4_field_options(target, 'bar')).to be nil
    end

    it "returns nil if target is occluded by a method override" do
      expect(helpers.infer_ar4_field_options(target, 'baz')).to be nil
    end
  end

  context "infer_ar5_field_options" do
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
      expect(helpers.infer_ar5_field_options(target, 'foo')).to eq({ type: :string })
    end

    it "returns nil if target is occluded by a serializer" do
      expect(helpers.infer_ar5_field_options(target, 'bar')).to be nil
    end

    it "returns nil if target is occluded by a method override" do
      expect(helpers.infer_ar5_field_options(target, 'baz')).to be nil
    end
  end
end