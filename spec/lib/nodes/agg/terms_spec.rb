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

  context "node has some registered aggregations" do
    before do
      node.aggregate('bar', build_node('qux'))
    end

    describe "render" do
      it "renders correctly" do
        expect(node.render)
          .to eq('terms' => { 'field' => 'foo' }, 'aggs' => { 'bar' => 'qux' })
      end
    end
  end
end
