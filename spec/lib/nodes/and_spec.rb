require 'spec_helper'

describe Elastic::Nodes::And do
  def build_and(_children)
    described_class.new.tap do |node|
      node.children = _children
    end
  end

  let(:child_a) { build_node 'foo' }
  let(:child_b) { build_node 'bar' }
  let(:child_c) { build_node 'fur' }

  let(:node) { build_and([child_a, child_b]) }
  let(:node_single) { build_and([child_a]) }

  describe "render" do
    it { expect(node.render).to eq('and' => ['foo', 'bar']) }
  end

  describe "simplify" do
    it { expect(node.simplify.render).to eq(node.render) }
    it { expect(node_single.simplify.render).to eq(child_a.render) }
  end

  describe "traversable" do
    it "traverses through query and aggregation nodes" do
      expect(node.pick_nodes.to_a.size).to eq(3)
      expect(node_single.pick_nodes.to_a.size).to eq(2)
    end
  end
end
