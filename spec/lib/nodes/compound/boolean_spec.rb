require 'spec_helper'

describe Elastic::Nodes::Boolean do
  let(:child_a) { DummyQuery.new 'foo' }
  let(:child_b) { DummyQuery.new 'bar' }
  let(:child_c) { DummyQuery.new 'fur' }

  let(:node) { described_class.new(must: [child_a, child_b], should: child_c) }
  let(:single_must) { described_class.new(must: child_a) }
  let(:single_should) { described_class.new(should: child_a) }

  describe "render" do
    it { expect(node.render).to eq({ 'must' => ['foo', 'bar'], 'should' => ['fur'] }) }
  end

  describe "simplify" do
    it { expect(single_must.simplify).to eq(child_a) }
    it { expect(single_should.simplify).to eq(single_should) }
  end
end