require 'spec_helper'

describe Elastic::Nodes::TopHits do
  let(:node) { described_class.new }

  let(:raw_result) do
    {
      'hits' => {
        'hits' => [
          { '_type' => '_doc', '_id' => 1 },
          { '_type' => '_doc', '_id' => 2 }
        ]
      }
    }
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render).to eq('top_hits' => {})
    end

    it "renders size option correctly" do
      node.size = 10
      expect(node.render).to eq('top_hits' => { 'size' => 10 })
    end
  end

  describe "handle_result" do
    it "builds a hit collection" do
      expect(node.handle_result(raw_result, nil)).to be_a Elastic::Results::HitCollection
      expect(node.handle_result(raw_result, nil).count).to eq 2
      expect(node.handle_result(raw_result, nil).each_hit.first.id).to eq 1
    end
  end
end
