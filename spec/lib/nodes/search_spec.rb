require 'spec_helper'

describe Elastic::Nodes::Search do
  let(:node) do
    described_class.build(build_node('qux')).tap do |node|
      node.aggregate 'baz', build_node('baz')
    end
  end

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

  describe "source" do
    it "fails if invalid values are set" do
      expect { node.source = false }.not_to raise_error
      expect { node.source = [] }.not_to raise_error
      expect { node.source = :foo }.to raise_error(ArgumentError)
    end
  end

  describe "traversable" do
    it "traverses through query and aggregation nodes" do
      expect(node.pick.to_a.size).to eq(3)
      expect(node.pick(Elastic::Nodes::Search).to_a.size).to eq(1)
    end
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
