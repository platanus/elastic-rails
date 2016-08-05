require 'spec_helper'

describe Elastic::Shims::Grouping do
  let(:child) { build_node('child') }
  let(:result) do
    level_2_a = Elastic::Results::BucketCollection.new(
      [
        Elastic::Results::Bucket.new('bar_1', 0, 'qux' => Elastic::Results::Metric.new(:qux)),
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
        Elastic::Results::Bucket.new('foo_1', 0, 'bar' => level_2_a),
        Elastic::Results::Bucket.new('foo_2', 0, 'bar' => level_2_b)
      ]
    )

    Elastic::Results::Root.new([], 0, 'foo' => level_1)
  end

  let(:node) { described_class.new(child) }

  before { allow(child).to receive(:handle_result).and_return result }

  describe "handle_result" do
    it "generates a grouped result" do
      expect(node.handle_result({}, nil)).to be_a Elastic::Results::GroupedResult
      expect(node.handle_result({}, nil).count).to eq 3

      keys, value = node.handle_result({}, nil).first
      expect(keys).to eq('foo' => 'foo_1', 'bar' => 'bar_1')
      expect(value['qux']).to eq :qux
    end
  end
end
