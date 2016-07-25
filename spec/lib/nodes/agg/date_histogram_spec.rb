require 'spec_helper'

describe Elastic::Nodes::Agg::DateHistogram do
  let(:histogram) { described_class.new }

  before { histogram.field = 'foo' }

  describe "interval=" do
    it "validates value is a valid interval or nil" do
      expect { histogram.interval = '1j' }.to raise_error ArgumentError
      expect { histogram.interval = '2d' }.not_to raise_error
      expect { histogram.interval = nil }.not_to raise_error
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(histogram.render).to eq('date_histogram' => { 'field' => 'foo' })
    end

    it "renders interval option correctly" do
      histogram.interval = '1d'
      expect(histogram.render).to eq('date_histogram' => { 'field' => 'foo', 'interval' => '1d' })
    end
  end

  # TODO: replace this by shared example (aggregable)

  describe "handle_result" do
    it "builds a bucket collection" do
      expect(histogram.handle_result('buckets' => [])).to be_a Elastic::Results::BucketCollection
      expect(histogram.handle_result('buckets' => [{ 'key' => :foo }]).count).to eq 1
      expect(histogram.handle_result('buckets' => [{ 'key' => :foo }]).first.key).to eq :foo
    end
  end

  context "node has some registered aggregations" do
    before do
      histogram.aggregate build_agg_node('bar', 'qux')
    end

    describe "render" do
      it "renders correctly" do
        expect(histogram.render)
          .to eq('date_histogram' => { 'field' => 'foo' }, 'aggs' => { 'bar' => 'qux' })
      end
    end

    describe "handle_result" do
      it "correctly parses each bucket aggregations" do
        expect(
          histogram.handle_result('buckets' => [{ 'key' => :foo, 'bar' => :bar }]).first[:bar]
        ).to eq :bar
      end
    end
  end
end
