require 'spec_helper'

describe Elastic::Nodes::Term do
  let(:node) { described_class.new }

  before { node.field = :foo }

  describe "clone" do
    it "copies every property" do
      node.terms = ['foo']
      node.boost = 2.0

      expect(node.clone).not_to be node
      expect(node.clone.field).to eq node.field
      expect(node.clone.terms.to_a).to eq node.terms.to_a
      expect(node.clone.boost).to eq node.boost
    end
  end

  describe "render" do
    it "renders correctly when single term is set" do
      node.terms = ['foo']

      expect(node.render).to eq('term' => { 'foo' => { 'value' => 'foo' } })
    end

    it "renders correctly when empty terms are set" do
      node.terms = []

      expect(node.render).to eq('terms' => { 'foo' => [] })
    end

    it "renders correctly when boost is set" do
      node.terms = ['foo']
      node.boost = 2.0

      expect(node.render).to eq('term' => { 'foo' => { 'value' => 'foo', 'boost' => 2.0 } })
    end

    it "renders correctly when multiple terms are set" do
      node.terms = ['foo', 'bar']

      expect(node.render).to eq('terms' => { 'foo' => ['foo', 'bar'] })
    end

    it "renders correctly when multiple terms and boost is set" do
      node.terms = ['foo', 'bar']
      node.boost = 2.0

      expect(node.render).to eq('terms' => { 'foo' => ['foo', 'bar'], 'boost' => 2.0 })
    end

    it "renders correctly when multiple terms and mode is :all and boost is set" do
      node.terms = ['foo', 'bar']
      node.mode = :all
      node.boost = 2.0

      expect(node.render).to eq(
        'bool' => {
          'must' => [{ 'term' => { 'foo' => 'foo' } }, { 'term' => { 'foo' => 'bar' } }],
          'boost' => 2.0
        }
      )
    end

    it "renders correctly when query_path option is given" do
      node.terms = ['foo']

      expect(node.render(query_path: 'qux'))
        .to eq('term' => { 'qux.foo' => { 'value' => 'foo' } })
    end
  end
end
