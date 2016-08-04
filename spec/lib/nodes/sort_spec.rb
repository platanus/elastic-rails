require 'spec_helper'

describe Elastic::Nodes::Sort do
  let(:node) { described_class.new }

  before { node.child = build_node({}) }

  describe 'add_sort' do
    it "adds a new sort to the node's render output" do
      expect { node.add_sort('foo', mode: 'avg') }.to change { node.render }.to(
        'sort' => [
          { 'foo' => { 'order' => 'asc', 'mode' => 'avg' } }
        ]
      )
    end

    it "validates sort order and mode params" do
      expect { node.add_sort('foo', mode: 'bar') }.to raise_error ArgumentError
      expect { node.add_sort('foo', mode: 'sum') }.not_to raise_error
      expect { node.add_sort('foo', order: 'ble') }.to raise_error ArgumentError
      expect { node.add_sort('foo', order: 'desc') }.not_to raise_error
    end
  end

  describe 'add_score_sort' do
    it "adds a new score sort to the node's render output" do
      expect { node.add_score_sort }.to change { node.render }.to(
        'sort' => [
          { '_score' => { 'order' => 'desc' } }
        ]
      )
    end
  end

  describe 'clone' do
    it "copies sort values" do
      node.add_score_sort
      new_node = node.clone
      node.add_sort 'foo'

      expect(new_node.render).to eq(
        'sort' => [
          { '_score' => { 'order' => 'desc' } }
        ]
      )
    end
  end

  describe 'simplify' do
    it "returns the child node if no sorts have been added" do
      expect(node.simplify).to eq(node.child)
    end
  end
end
