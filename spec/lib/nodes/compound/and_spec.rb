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
    it { expect(node.render).to eq({ 'and' => ['foo', 'bar'] }) }
  end

  describe "simplify" do
    it { expect(node.simplify.render).to eq(node.render) }
    it { expect(node_single.simplify.render).to eq(child_a.render) }
  end

  context "when child nodes are nested queries" do
    let(:nested_a1) { Elastic::Nodes::Nested.build 'nested_a', child_a }
    let(:nested_a2) { Elastic::Nodes::Nested.build 'nested_a', child_b }
    let(:nested_b) { Elastic::Nodes::Nested.build 'nested_b', child_c }

    let(:complex_node) { build_and([nested_a1, nested_a2, nested_b]) }

    describe "simplify" do
      it "moves nested queries up in the hierarchy" do
        expect(complex_node.simplify.render).to eq({
          "and" => [
            {
              "nested" => {
                "path" => "nested_a",
                "query" => {
                  "and" => ['foo', 'bar']
                }
              }
            },
            {
              "nested" => {
                "path" => "nested_b",
                "query" => 'fur'
              }
            }
          ]
        })
      end
    end
  end
end