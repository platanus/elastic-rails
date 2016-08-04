require 'spec_helper'

describe Elastic::Commands::BuildSortFromParams do
  let!(:foo_index) do
    build_index('FooIndex', migrate: true) do
      field :foo, type: :string
      field :bar, type: :date

      nested :nested do
        field :field, type: :string
      end
    end
  end

  def perform(*_params)
    described_class.for index: foo_index, params: _params
  end

  it "builds the correct sort node" do
    expect(perform(:foo)).to be_a Elastic::Nodes::Sort
    expect(perform(:foo).sorts.count).to eq(2)
    expect(perform(:foo, :bar).sorts.count).to eq(3)
    expect { perform(:foo, :qux) }.to raise_error ArgumentError
  end
end
