require 'spec_helper'

describe Elastic::Nodes::Agg::BaseMetric do
  let(:metric_class) do
    Class.new(described_class) do
      def metric
        'foo'
      end
    end
  end

  let(:metric) { metric_class.build('bar') }

  describe "render" do
    it "renders correctly" do
      expect(metric.render).to eq('foo' => { 'field' => 'bar' })
    end

    it "renders missing option correctly" do
      metric.missing = 20
      expect(metric.render).to eq('foo' => { 'field' => 'bar', 'missing' => 20 })
    end
  end
end
