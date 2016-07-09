require 'spec_helper'

describe Elastic::Nodes::Boolean do
  def build_boolean(must: [], should: [], boost: nil)
    described_class.new.tap do |node|
      node.musts = must
      node.shoulds = should
      node.boost = boost
    end
  end

  let(:child_a) { build_node 'foo' }
  let(:child_b) { build_node 'bar' }
  let(:child_c) { build_node 'fur' }

  let(:node) { build_boolean(must: [child_a, child_b], should: [child_c]) }
  let(:single_must) { build_boolean(must: [child_a]) }
  let(:single_should) { build_boolean(should: [child_a]) }

  describe "render" do
    it { expect(node.render).to eq({ 'must' => ['foo', 'bar'], 'should' => ['fur'] }) }
  end

  describe "simplify" do
    it { expect(single_must.simplify).to eq(child_a) }
    it { expect(single_should.simplify).to eq(single_should) }
  end
end