require 'spec_helper'

describe Elastic::Nodes::Term do
  let(:node_single) { described_class.new(:foo, ['foo']) }
  let(:node_multiple) { described_class.new(:foo, ['foo', 'bar']) }

  describe "render" do
    it { expect(node_single.render).to eq({ 'term' => { 'foo' => 'foo' } }) }
    it { expect(node_multiple.render).to eq({ 'terms' => { 'foo' => ['foo', 'bar'] } }) }
  end
end