require 'spec_helper'

describe Elastic::Nodes::Nested do
  let(:node) { described_class.new }

  before do
    node.path = 'foo'
    node.child = build_node(:foo)
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render).to eq('nested' => { 'path' => 'foo', 'query' => :foo })
    end

    it "renders correctly when score_mode options is set" do
      node.score_mode = :sum

      expect(node.render)
        .to eq('nested' => { 'path' => 'foo', 'query' => :foo, 'score_mode' => 'sum' })
    end
  end

  describe "simplify" do
    it "calls child node simplify" do
      expect(node.child).to receive(:simplify)
      expect(node.simplify).to be_a described_class
    end

    it "merges nodes if child is a nested node too" do
      parent_node = described_class.new
      parent_node.path = 'bar'
      parent_node.child = node

      expect(node.child).to receive(:simplify)

      simplified = parent_node.simplify
      expect(simplified.path).to eq 'bar.foo'
      expect(simplified.child).not_to be_a described_class
    end
  end
end
