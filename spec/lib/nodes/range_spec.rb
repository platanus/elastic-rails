require 'spec_helper'

describe Elastic::Nodes::Range do
  let(:node) { described_class.new }

  before { node.field = :foo }

  describe "render" do
    it "renders correctly when gt and lt are set" do
      node.gt = 20
      node.lt = 30

      expect(node.render).to eq('range' => { 'foo' => { 'gt' => 20, 'lt' => 30 } })
    end

    it "renders correctly when gte and lte are set" do
      node.gte = 20
      node.lte = 30

      expect(node.render).to eq('range' => { 'foo' => { 'gte' => 20, 'lte' => 30 } })
    end

    it "renders correctly when boost is set" do
      node.gt = 20
      node.boost = 2.0

      expect(node.render).to eq('range' => { 'foo' => { 'gt' => 20, 'boost' => 2.0 } })
    end

    it "renders correctly when query_path option is given" do
      node.gt = 20
      node.lt = 30

      expect(node.render(query_path: 'qux'))
        .to eq('range' => { 'qux.foo' => { 'gt' => 20, 'lt' => 30 } })
    end
  end

  describe "clone" do
    it "copies every property" do
      node.gt = 1
      node.gte = 2
      node.lt = 3
      node.lte = 4
      node.boost = 2.0

      expect(node.clone).not_to be node
      expect(node.clone.field).to eq node.field
      expect(node.clone.gt).to eq node.gt
      expect(node.clone.gte).to eq node.gte
      expect(node.clone.lt).to eq node.lt
      expect(node.clone.lte).to eq node.lte
      expect(node.clone.boost).to eq node.boost
    end
  end
end
