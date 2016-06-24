require 'spec_helper'

describe Elastic::Nodes::And do
  let(:child_a) { DummyQuery.new 'foo' }
  let(:child_b) { DummyQuery.new 'bar' }
  let(:child_c) { DummyQuery.new 'fur' }

  let(:node) { described_class.new([child_a, child_b]) }
  let(:node_single) { described_class.new([child_a]) }

  describe "render" do
    it { expect(node.render).to eq({ 'and' => ['foo', 'bar'] }) }
  end

  describe "simplify" do
    it { expect(node.simplify.render).to eq(node.render) }
    it { expect(node_single.simplify.render).to eq(child_a.render) }
  end

  context "when child nodes are nested queries" do
    let(:nested_a1) { Elastic::Nodes::Nested.new 'nested_a', child_a }
    let(:nested_a2) { Elastic::Nodes::Nested.new 'nested_a', child_b }
    let(:nested_b) { Elastic::Nodes::Nested.new 'nested_b', child_c }

    let(:complex_node) { described_class.new([nested_a1, nested_a2, nested_b]) }

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