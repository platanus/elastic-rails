require 'spec_helper'

describe Elastic::Nodes::Range do
  let(:node_a) { described_class.new(:foo, gte: 20, lt: 30) }
  let(:node_b) { described_class.new(:bar, gt: 20, lte: 30) }

  describe "render" do
    it { expect(node_a.render).to eq({ 'range' => { 'foo' => { 'gte' => 20, 'lt' => 30 } } }) }
    it { expect(node_b.render).to eq({ 'range' => { 'bar' => { 'gt' => 20, 'lte' => 30 } } }) }
  end
end