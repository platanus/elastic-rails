require 'spec_helper'

describe Elastic::Commands::BuildQueryFromParams do
  let!(:foo_index) do
    build_index('FooIndex', migrate: true) do
      field :foo, type: :string
      field :bar, type: :string, transform: -> { "transform(#{self})" }
      field :term, type: :term
      field :string, type: :string
      field :long, type: :long

      nested :nested do
        field :field, type: :string
      end
    end
  end

  def perform(*_params)
    described_class.for index: foo_index, params: _params
  end

  it "builds the correct compound node depending on params structure" do
    expect(perform(foo: 'foo', bar: 'bar')).to be_a Elastic::Nodes::And
    expect(perform({ foo: 'foo' }, { bar: 'bar' })).to be_a Elastic::Nodes::Or
  end

  it "fails if an unregistered field is provided" do
    expect { perform(foo: 'foo', unregistered: 'bar') }.to raise_error(ArgumentError)
  end

  it "builds the correct term node depending on field type and value" do
    expect(perform(term: 'tag')).to be_a Elastic::Nodes::Term
    expect(perform(term: 'tag').terms.to_a).to eq ['tag']
  end

  it "builds the correct match node depending on field type and value" do
    expect(perform(string: 'phrase')).to be_a Elastic::Nodes::Match
    expect(perform(string: 'phrase').query).to eq 'phrase'
  end

  it "builds the correct range node depending on field type and value" do
    expect(perform(long: (1..10))).to be_a Elastic::Nodes::Range
    expect(perform(long: (1..10)).gte).to eq 1
    expect(perform(long: (1..10)).lte).to eq 10
    expect(perform(long: (1...10)).lt).to eq 10
  end

  it "builds the correct query node type depending on options" do
    expect(perform(bar: { term: 'tag' })).to be_a Elastic::Nodes::Term
    expect(perform(bar: { matches: 'phrase' })).to be_a Elastic::Nodes::Match
    expect(perform(bar: { gte: 'gte' })).to be_a Elastic::Nodes::Range
    expect(perform(bar: { gt: 'gt' })).to be_a Elastic::Nodes::Range
    expect(perform(bar: { lte: 'lte' })).to be_a Elastic::Nodes::Range
    expect(perform(bar: { lt: 'lt' })).to be_a Elastic::Nodes::Range
  end

  it "applies type transform to nodes values" do
    expect(perform(bar: { term: 'tag' }).terms.to_a).to eq ["transform(tag)"]
    expect(perform(bar: { matches: 'phrase' }).query).to eq "transform(phrase)"
    expect(perform(bar: { gte: 'gte' }).gte).to eq "transform(gte)"
    expect(perform(bar: { gt: 'gt' }).gt).to eq "transform(gt)"
    expect(perform(bar: { lte: 'lte' }).lte).to eq "transform(lte)"
    expect(perform(bar: { lt: 'lt' }).lt).to eq "transform(lt)"
  end

  it "wraps nested fields in a nested node" do
    expect(perform('nested.field' => { matches: 'tag' })).to be_a Elastic::Nodes::Nested
    expect(perform('nested.field' => { matches: 'tag' }).child).to be_a Elastic::Nodes::Match
  end

  it "builds the correct nested node if a nested query is provided" do
    expect(perform(nested: { field: 'tag' })).to be_a Elastic::Nodes::Nested
    expect(perform(nested: { field: 'tag' }).child).to be_a Elastic::Nodes::Match
  end
end
