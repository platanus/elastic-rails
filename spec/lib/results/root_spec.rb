require 'spec_helper'

describe Elastic::Results::Root do
  let(:hit_1) { Elastic::Results::Hit.new('hit', 1, 0, {}) }
  let(:hit_2) { Elastic::Results::Hit.new('hit', 1, 0, {}) }
  let(:agg_1) { Elastic::Results::Metric.new(:foo) }
  let(:agg_2) do
    Elastic::Results::BucketCollection.new(
      [Elastic::Results::Bucket.new(:qux, 0, 'baz' => agg_3)]
    )
  end
  let(:agg_3) { Elastic::Results::Metric.new(:baz) }

  let(:result) do
    described_class.new([hit_1, hit_2], 2, 'foo' => agg_1, 'bar' => agg_2)
  end

  let(:node) { metric_class.build('bar') }

  describe "traversable" do
    it "goes through every hit and aggregation" do
      expect(result.pick.to_a).to include(result, hit_1, hit_2, agg_1, agg_2, agg_3)
      expect(result.pick(Elastic::Results::Hit).to_a).to eq [hit_1, hit_2]
    end
  end
end
