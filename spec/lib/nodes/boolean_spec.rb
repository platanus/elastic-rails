require 'spec_helper'

describe Elastic::Nodes::Boolean do
  def build_boolean(must: [], must_not: [], should: [], filter: [], boost: nil)
    described_class.new.tap do |node|
      node.musts = must
      node.must_nots = must_not
      node.shoulds = should
      node.filters = filter
      node.boost = boost
    end
  end

  let(:child_a) { build_node 'foo' }
  let(:child_b) { build_node 'bar' }
  let(:child_c) { build_node 'fur' }
  let(:child_d) { build_node 'qux' }
  let(:child_e) { build_node 'baz' }

  let(:node) do
    build_boolean(
      must: [child_a, child_b],
      should: [child_c],
      filter: [child_d],
      must_not: [child_e]
    )
  end

  let(:single_must) { build_boolean(must: [child_a]) }
  let(:single_should) { build_boolean(should: [child_a]) }
  let(:single_filter) { build_boolean(filter: [child_a]) }
  let(:single_must_not) { build_boolean(must_not: [child_a]) }

  describe "disable_coord" do
    it "is set to true by default if coord_similarity is disabled in configuration" do
      expect { Elastic.configure coord_similarity: false }
        .to change { build_boolean.disable_coord }.to true
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render)
        .to eq(
          'bool' => {
            'must' => ['foo', 'bar'],
            'should' => ['fur'],
            'filters' => ['qux'],
            'must_not' => ['baz']
          }
        )
    end
  end

  describe "simplify" do
    it { expect(single_must.simplify).to eq(child_a) }
    it { expect(single_should.simplify).to eq(child_a) }
    it { expect(single_filter.simplify).to eq(single_filter) }
    it { expect(single_must_not.simplify).to eq(single_must_not) }
  end
end
