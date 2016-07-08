require 'spec_helper'

describe Elastic::Nodes::Term do
  def build_term(_field, _terms, _boost = nil)
    described_class.new.tap do |node|
      node.field = _field
      node.terms = _terms
      node.boost = _boost unless _boost.nil?
    end
  end

  let(:node_single) { build_term(:foo, ['foo']) }
  let(:node_boost) { build_term(:foo, ['foo'], 2.0) }
  let(:node_multiple) { build_term(:foo, ['foo', 'bar']) }
  let(:node_boost_multi) { build_term(:foo, ['foo', 'bar'], 2.0) }

  describe "render" do
    it "renders correctly" do
      expect(node_single.render)
      .to eq({ 'term' => { 'foo' => { 'value' => 'foo' } } })
    end

    it "renders correctly" do
      expect(node_boost.render)
        .to eq({ 'term' => { 'foo' => { 'value' => 'foo', 'boost' => 2.0 } } })
    end

    it "renders correctly" do
      expect(node_multiple.render)
        .to eq({ 'terms' => { 'foo' => ['foo', 'bar'] } })
    end

    it "renders correctly" do
      expect(node_boost_multi.render)
        .to eq({ 'terms' => { 'foo' => ['foo', 'bar'], 'boost' => 2.0 } })
    end
  end
end