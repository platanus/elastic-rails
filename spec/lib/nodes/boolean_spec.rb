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

  describe "disable_coord" do
    it "is set to true by default if coord_similarity is disabled in configuration" do
      expect { Elastic.configure coord_similarity: false }
        .to change { build_boolean.disable_coord }.to true
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render)
        .to eq('bool' => { 'must' => ['foo', 'bar'], 'should' => ['fur'] })
    end
  end

  describe "simplify" do
    it { expect(single_must.simplify).to eq(child_a) }
    it { expect(single_should.simplify).to eq(child_a) }
  end
end
