require 'spec_helper'

describe Elastic::Nodes::Shims::Grouping do
  let(:child) { build_node('child') }
  let(:result) do
    level_2_a = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('bar_1', 'qux' => Elastic::Results::Metric.new(:qux)),
        Elastic::Results::Bucket.new('bar_2', {})
      ]
    )

    level_2_b = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('bar_3', {})
      ]
    )

    level_1 = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('foo_1', 'bar' => level_2_a),
        Elastic::Results::Bucket.new('foo_2', 'bar' => level_2_b)
      ]
    )

    Elastic::Results::Root.new([], 'foo' => level_1)
  end

  let(:node) { described_class.new(child) }

  before { allow(child).to receive(:handle_result).and_return result }

  describe "handle_result" do
    it "generates a grouped result" do
      expect(node.handle_result({})).to be_a Elastic::Results::GroupedResult
      expect(node.handle_result({}).count).to eq 3
      expect(node.handle_result({}).first).to be_a Elastic::Results::GroupedBucket
      expect(node.handle_result({}).first.keys('foo')).to eq('foo_1')
      expect(node.handle_result({}).first.keys('bar')).to eq('bar_1')
      expect(node.handle_result({}).first['qux']).to eq :qux
    end
  end
end
