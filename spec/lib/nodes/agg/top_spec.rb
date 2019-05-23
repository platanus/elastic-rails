require 'spec_helper'

describe Elastic::Nodes::Agg::Top do
  let(:field_name) { 'bar' }
  let(:node) { described_class.build('foo', field_name) }

  let(:raw_result) do
    {
      'hits' => {
        'hits' => [
          { '_type' => 'FooType', '_id' => 1, '_source' => { field_name => 200 } }
        ]
      }
    }
  end

  describe "render" do
    it "renders correctly" do
      expect(node.render)
        .to eq('top_hits' => { "_source" => { "includes" => [field_name] }, "size" => 1 })
    end

    it "renders sort option correctly" do
      node.add_sort(:qux, order: :desc)

      expect(node.render)
        .to eq(
          'top_hits' => {
            "_source" => { "includes" => ["bar"] },
            "size" => 1,
            "sort" => [{ 'qux' => { "order" => "desc" } }]
          }
        )
    end
  end

  describe "handle_result" do
    it "builds a metric" do
      expect(node.handle_result(raw_result, nil)).to be_a Elastic::Results::Metric
      expect(node.handle_result(raw_result, nil).as_value).to eq 200
    end
  end
end
