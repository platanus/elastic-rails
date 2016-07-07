require 'spec_helper'

describe Elastic::Nodes::Match do
  let(:node_a) { described_class.new(:foo, 'hello world') }
  let(:node_b) { described_class.new(:bar, 'hello world', mode: 'phrase') }

  describe "render" do
    it "renders ok" do
      expect(node_a.render)
        .to eq({ 'match' => { 'foo' => { 'query' => 'hello world' , 'type' => 'boolean' } } })
    end

    it "renders ok" do
      expect(node_b.render)
        .to eq({ 'match' => { 'bar' => { 'query' => 'hello world' , 'type' => 'phrase' } } })
    end

    it "validates mode attribute" do
      expect { node_a.mode = 'phrase' }.not_to raise_error
      expect { node_a.mode = 'teapot' }.to raise_error ArgumentError
    end
  end
end