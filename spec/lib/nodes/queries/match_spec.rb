require 'spec_helper'

describe Elastic::Nodes::Match do
  def build_match(_field, _query, mode: nil, boost: nil)
    described_class.new.tap do |node|
      node.field = _field
      node.query = _query
      node.mode = mode unless mode.nil?
      node.boost = boost unless boost.nil?
    end
  end

  let(:node_a) { build_match(:foo, 'hello world') }
  let(:node_b) { build_match(:bar, 'hello world', mode: 'phrase') }
  let(:node_boost) { build_match(:bar, 'hello world', boost: '2.0') }

  describe "mode" do
    it "fails if an invalid mode is provided" do
      expect { node_a.mode = 'cow' }.to raise_error ArgumentError
      expect { node_a.mode = nil }.not_to raise_error
      expect { node_a.mode = 'phrase' }.not_to raise_error
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(node_a.render)
        .to eq({ 'match' => { 'foo' => { 'query' => 'hello world' } } })
    end

    it "renders correctly" do
      expect(node_b.render)
        .to eq({ 'match' => { 'bar' => { 'query' => 'hello world' , 'type' => 'phrase' } } })
    end

    it "renders correctly" do
      expect(node_boost.render)
        .to eq({ 'match' => { 'bar' => { 'query' => 'hello world' , 'boost' => 2.0 } } })
    end

    it "validates mode attribute" do
      expect { node_a.mode = 'phrase' }.not_to raise_error
      expect { node_a.mode = 'teapot' }.to raise_error ArgumentError
    end
  end
end