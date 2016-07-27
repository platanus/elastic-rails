require 'spec_helper'

describe Elastic::Nodes::Match do
  let(:node) { described_class.new }

  before { node.field = :foo }

  describe "mode" do
    it "fails if an invalid mode is provided" do
      expect { node.mode = 'cow' }.to raise_error ArgumentError
      expect { node.mode = nil }.not_to raise_error
      expect { node.mode = 'phrase' }.not_to raise_error
    end
  end

  describe "clone" do
    it "copies every property" do
      node.query = 'hello world'
      node.mode = :phrase
      node.boost = 2.0

      expect(node.clone).not_to be node
      expect(node.clone.query).to eq node.query
      expect(node.clone.mode).to eq node.mode
      expect(node.clone.boost).to eq node.boost
    end
  end

  describe "render" do
    it "renders correctly if query is set" do
      node.query = 'hello world'
      expect(node.render).to eq('match' => { 'foo' => { 'query' => 'hello world' } })
    end

    it "renders correctly if mode is changed" do
      node.query = 'hello world'
      node.mode = :phrase

      expect(node.render)
        .to eq('match' => { 'foo' => { 'query' => 'hello world', 'type' => 'phrase' } })
    end

    it "renders correctly if boost is set" do
      node.query = 'hello world'
      node.boost = 2.0

      expect(node.render)
        .to eq('match' => { 'foo' => { 'query' => 'hello world', 'boost' => 2.0 } })
    end
  end
end
