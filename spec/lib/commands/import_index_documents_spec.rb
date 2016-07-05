require 'spec_helper'

describe Elastic::Commands::ImportIndexDocuments do
  let(:foo_type) do
    Class.new(Struct.new(:id, :name)) do
      def self.to_s
        'FooType'
      end
    end
  end

  let(:foo_index) do
    Class.new(Elastic::Type) do
      def self.to_s
        'FooIndex'
      end

      field :name, type: :string
    end.tap { |idx| idx.target = foo_type }
  end

  def perform(_options = {})
    described_class.for(_options.merge(index: foo_index))
  end

  before { foo_index.mapping.migrate }

  context "target provides a proper each method" do
    before do
      class << foo_type
        def each(&_block)
          [new(1, 'hello'), new(2, 'world')].each(&_block)
        end
      end
    end

    it "indexes returned documents" do
      expect { perform }
        .to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(2)
    end
  end

  context "target does not provide a for_each or each method" do
    before do
      class << foo_type
        def each_tag(&_block)
          [new(1, 'hello'), new(2, 'world')].each(&_block)
        end
      end
    end

    it "fails if method is not provided" do
      expect { perform }.to raise_error(NoMethodError)
    end

    it "indexes returned documents if method is provided" do
      expect { perform method: :each_tag }
        .to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(2)
    end
  end

  context "a :transform option is provided" do
    before do
      class << foo_type
        def to_a
          [new(1, 'hello'), new(2, 'world')]
        end
      end
    end

    it "it calls a target's method if a symbol is given" do
      expect { perform(transform: :to_a) }
        .to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(2)
    end

    it "it executes the given ruby code in the target context if a string is provided" do
      expect { perform(transform: "to_a[0...1]") }
        .to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(1)
    end

    it "it executes the given Proc in the target context if a proc is provided" do
      expect { perform(transform: -> { to_a }) }
        .to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(2)
    end
  end
end