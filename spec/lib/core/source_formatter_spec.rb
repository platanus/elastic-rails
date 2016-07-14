require 'spec_helper'

describe Elastic::Core::SourceFormatter do
  let(:index) do
    build_index('Foo', migrate: true) do
      field :foo, type: :string
      field :bar, type: :long
      nested :tags do
        field :name, type: :term
      end
    end
  end

  let(:formatter) { described_class.new index.mapping }

  describe "format" do
    it "properly formats string fields" do
      expect(formatter.format('foo' => ['hello', 'world'])).to eq('foo' => 'hello world')
    end

    it "does not affect other fields" do
      expect(formatter.format('bar' => 20)).to eq('bar' => 20)
    end
  end
end
