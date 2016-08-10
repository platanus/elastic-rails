require 'spec_helper'

describe Elastic::Shims::Grouping do
  let(:child) do
    Elastic::Nodes::Search.build(build_node('query')).tap do |node|
      first_agg = Elastic::Nodes::Agg::Terms.build('first', :foo)
      second_agg = Elastic::Nodes::Agg::Terms.build('second', :bar)
      hits = Elastic::Nodes::TopHits.new

      second_agg.aggregate hits
      first_agg.aggregate second_agg
      node.aggregate first_agg
    end
  end

  let(:result) do
    level_2_a = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('bar_1', 0, qux: Elastic::Results::Metric.new(:qux)),
        Elastic::Results::Bucket.new('bar_2', 0, {})
      ]
    )

    level_2_b = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('bar_3', 0, {})
      ]
    )

    level_1 = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('foo_1', 0, second: level_2_a),
        Elastic::Results::Bucket.new('foo_2', 0, second: level_2_b)
      ]
    )

    Elastic::Results::Root.new([], 0, first: level_1)
  end

  let(:node) { described_class.new(child) }

  before { allow(child).to receive(:handle_result).and_return result }

  describe "handle_result" do
    it "generates a grouped result" do
      expect(node.handle_result({}, nil)).to be_a Elastic::Results::GroupedResult
      expect(node.handle_result({}, nil).count).to eq 3

      keys, value = node.handle_result({}, nil).first
      expect(keys).to eq(first: 'foo_1', second: 'bar_1')
      expect(value['qux']).to eq :qux
    end
  end
end
