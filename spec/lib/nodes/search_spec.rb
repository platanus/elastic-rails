require 'spec_helper'

describe Elastic::Nodes::Search do
  let(:node) { described_class.build(build_node('qux')) }

  let(:result) do
    {
      'hits' => {
        'hits' => [
          { '_id' => 1 },
          { '_id' => 2 }
        ]
      },
      'aggregations' => {
        'bar' => :bar
      }
    }
  end

  describe "handle_result" do
    it "returns root result structure" do
      expect(node.handle_result(result)).to be_a Elastic::Results::Root
    end

    it "correctly parses each hit" do
      expect(node.handle_result(result).count).to eq(2)
      expect(node.handle_result(result).first.id).to eq(1)
    end
  end

  context "node has some aggregations" do
    before { node.aggregate(:bar, build_node('bar')) }

    describe "handle_result" do
      it "correctly parses each aggregations" do
        expect(node.handle_result(result)[:bar]).to eq :bar
      end
    end
  end
end
