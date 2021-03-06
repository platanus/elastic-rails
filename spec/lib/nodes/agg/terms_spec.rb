require 'spec_helper'

describe Elastic::Nodes::Agg::Terms do
  let(:node) { described_class.new }

  before { node.field = 'foo' }

  describe "render" do
    it "renders correctly" do
      expect(node.render).to eq('terms' => { 'field' => 'foo' })
    end

    it "renders size option correctly" do
      node.size = 10
      expect(node.render).to eq('terms' => { 'field' => 'foo', 'size' => 10 })
    end
  end

  describe "handle_result" do
    it "builds a bucket collection" do
      expect(
        node.handle_result({ 'buckets' => [] }, formatter_double)
      ).to be_a Elastic::Results::BucketCollection

      expect(
        node.handle_result({ 'buckets' => [{ 'key' => :foo }] }, formatter_double).count
      ).to eq 1

      expect(
        node.handle_result({ 'buckets' => [{ 'key' => :foo }] }, formatter_double).first.key
      ).to eq :foo
    end
  end

  context "node has some registered aggregations" do
    before do
      node.aggregate build_agg_node('bar', 'qux')
    end

    describe "render" do
      it "renders correctly" do
        expect(node.render)
          .to eq('terms' => { 'field' => 'foo' }, 'aggs' => { 'bar' => 'qux' })
      end
    end

    describe "handle_result" do
      it "correctly parses each bucket aggregations" do
        expect(
          node.handle_result(
            { 'buckets' => [{ 'key' => :foo, 'bar' => :bar }] },
            formatter_double
          ).first[:bar]
        ).to eq :bar
      end
    end
  end
end
