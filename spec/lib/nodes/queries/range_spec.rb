require 'spec_helper'

describe Elastic::Nodes::Range do
  def build_range(_field, _options = {})
    described_class.new.tap do |node|
      node.field = _field
      [:gte, :gt, :lte, :lt].each do |opt|
        node.send("#{opt}=", _options[opt]) if _options.key? opt
      end
      node.boost = _options[:boost]
    end
  end

  let(:node_a) { build_range(:foo, gte: 20, lt: 30) }
  let(:node_b) { build_range(:bar, gt: 20, lte: 30) }
  let(:node_b_boost) { build_range(:bar, gt: 20, lte: 30, boost: 20.0) }

  describe "render" do
    it "renders correctly" do
      expect(node_a.render)
        .to eq({ 'range' => { 'foo' => { 'gte' => 20, 'lt' => 30 } } })
    end

    it "renders correctly" do
      expect(node_b.render)
        .to eq({ 'range' => { 'bar' => { 'gt' => 20, 'lte' => 30 } } })
    end

    it "renders correctly" do
      expect(node_b_boost.render)
        .to eq({ 'range' => { 'bar' => { 'gt' => 20, 'lte' => 30, 'boost' => 20.0 } } })
    end
  end
end