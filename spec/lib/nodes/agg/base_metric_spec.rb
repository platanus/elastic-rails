require 'spec_helper'

describe Elastic::Nodes::Agg::BaseMetric do
  let(:metric_class) do
    Class.new(described_class) do
      def metric
        'foo'
      end
    end
  end

  let(:node) { metric_class.build('bar') }

  describe "clone" do
    it "copies every property" do
      node.missing = 20

      expect(node.clone).not_to be node
      expect(node.clone.field).to eq node.field
      expect(node.clone.missing).to eq node.missing
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render).to eq('foo' => { 'field' => 'bar' })
    end

    it "renders missing option correctly" do
      node.missing = 20

      expect(node.render).to eq('foo' => { 'field' => 'bar', 'missing' => 20 })
    end
  end

  describe "handle_result" do
    it "builds a metric" do
      expect(node.handle_result('value' => :foo)).to be_a Elastic::Results::Metric
      expect(node.handle_result('value' => :foo).value).to eq :foo
    end
  end
end
