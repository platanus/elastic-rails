require 'spec_helper'

describe Elastic::Query do
  let(:root_index) do
    build_index('RootIndex', migrate: true) do
      field :foo, type: :string
      field :bar, type: :long
      nested :tags do
        field :name, type: :term
      end
    end
  end

  let(:query) { described_class.new(root_index) }

  describe "should" do
    it "returns a new query" do
      expect(query.should(foo: 'teapot')).not_to be query
    end

    it "fails if given field name is not defined" do
      expect { query.should(teampot: 'foo') }.to raise_error ArgumentError
    end

    it "adds a new 'should' query element" do
      new_query = query.should(foo: 'teapot')
      expect(new_query.root.query.shoulds.count).to eq(1)
      expect(new_query.root.query.shoulds.first).to be_a Elastic::Nodes::Match
      new_query = new_query.should(foo: 'teapot')
      expect(new_query.root.query.shoulds.count).to eq(2)
    end
  end

  describe "must" do
    it "returns a new query" do
      expect(query.must(foo: 'teapot')).not_to be query
    end

    it "adds a new must query element" do
      new_query = query.must(bar: 20)
      expect(new_query.root.query.musts.count).to eq(1)
      expect(new_query.root.query.musts.first).to be_a Elastic::Nodes::Term
      new_query = new_query.must(foo: 'teapot')
      expect(new_query.root.query.musts.count).to eq(2)
    end
  end

  describe "boost" do
    it "returns a new query" do
      expect(query.boost(2.0) { must(bar: 20) }).not_to be query
    end

    it "adds the proper query element wrapped in a function score node" do
      new_query = query.boost(2.0) { must(bar: 20).should(foo: 'teapot') }
      expect(new_query.root.query.musts.count).to eq(1)
      expect(new_query.root.query.musts.first).to be_a Elastic::Nodes::FunctionScore
      expect(new_query.root.query.musts.first.boost).to eq 2.0
      expect(new_query.root.query.musts.first.query).to be_a Elastic::Nodes::Term

      expect(new_query.root.query.shoulds.count).to eq(1)
      expect(new_query.root.query.shoulds.first).to be_a Elastic::Nodes::FunctionScore
      expect(new_query.root.query.shoulds.first.boost).to eq 2.0
      expect(new_query.root.query.shoulds.first.query).to be_a Elastic::Nodes::Match
    end
  end
end
