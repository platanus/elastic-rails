require 'spec_helper'

describe Elastic::Results::ScoredCollection do
  let(:item_1) { Elastic::Results::ScoredItem.new(:foo, 1.0) }
  let(:item_2) { Elastic::Results::ScoredItem.new(:bar, 2.0) }

  let(:collection) do
    described_class.new([item_1, item_2])
  end

  describe "enumerable" do
    it "enumerates item data" do
      expect(collection.to_a).to eq [:foo, :bar]
    end
  end

  describe "count" do
    it "returns item count" do
      expect(collection.count).to eq 2
    end
  end

  describe "each_with_score" do
    it "returns item's data and score" do
      expect(collection.each_with_score.to_a).to eq [[:foo, 1.0], [:bar, 2.0]]
    end
  end

  describe "map_with_score" do
    it "returns a new scored collection with the new data" do
      new_collection = collection.map_with_score { |sd| sd.data.length }
      expect(new_collection).to be_a described_class
      expect(new_collection.to_a).to eq [3, 3]
    end
  end

  describe "traversable" do
    it "goes through every item" do
      expect(collection.pick.to_a).to include(collection, item_1, item_2)
      expect(collection.pick(Elastic::Results::ScoredItem).to_a).to eq [item_1, item_2]
    end
  end
end
