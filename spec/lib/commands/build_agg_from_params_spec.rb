require 'spec_helper'

describe Elastic::Commands::BuildAggFromParams do
  let!(:foo_index) do
    build_index('FooIndex', migrate: true) do
      field :foo, type: :text
      field :bar, type: :date

      nested :nested do
        field :field, type: :text
      end
    end
  end

  def perform(*_params)
    described_class.for index: foo_index, params: _params
  end

  it "builds the correct agg node" do
    expect(perform(:foo)).to be_a Elastic::Nodes::Agg::Terms
    expect(perform(:bar)).to be_a Elastic::Nodes::Agg::DateHistogram
    expect(perform(:bar).time_zone.name).to eq 'UTC'
    expect(perform(:bar, interval: '2h').interval).to eq '2h'
  end
end
