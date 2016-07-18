require 'spec_helper'

describe Elastic::Nodes::Agg::DateHistogram do
  let(:histogram) { described_class.new }

  before { histogram.field = 'foo' }

  describe "interval=" do
    it "validates value is a valid interval or nil" do
      expect { histogram.interval = '1j' }.to raise_error ArgumentError
      expect { histogram.interval = '2d' }.not_to raise_error
      expect { histogram.interval = nil }.not_to raise_error
    end
  end

  describe "render" do
    it "renders correctly" do
      expect(histogram.render).to eq('date_histogram' => { 'field' => 'foo' })
    end

    it "renders interval option correctly" do
      histogram.interval = '1d'
      expect(histogram.render).to eq('date_histogram' => { 'field' => 'foo', 'interval' => '1d' })
    end
  end

  context "node has some registered aggregations" do
    before do
      histogram.aggregate('bar', build_node('qux'))
    end

    describe "render" do
      it "renders correctly" do
        expect(histogram.render)
          .to eq('date_histogram' => { 'field' => 'foo' }, 'aggs' => { 'bar' => 'qux' })
      end
    end
  end
end
