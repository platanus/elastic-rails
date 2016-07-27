require 'spec_helper'

describe Elastic::Core::SourceFormatter do
  let(:es_date_str) { '2016-07-14T15:40:27.446-04:00' }

  let(:index) do
    build_index('Foo', migrate: true) do
      field :foo, type: :date
      field :bar, type: :long
      nested :tags do
        field :date, type: :date
      end
    end
  end

  let(:formatter) { described_class.new index.mapping }

  describe "format" do
    it "properly formats date fields" do
      expect(formatter.format('foo' => es_date_str))
        .to eq('foo' => Time.parse(es_date_str))
    end

    it "does not affect other fields" do
      expect(formatter.format('bar' => 20)).to eq('bar' => 20)
    end

    it "handles nested fields" do
      expect(formatter.format('tags' => [{ 'date' => es_date_str }]))
        .to eq('tags' => [{ 'date' => Time.parse(es_date_str) }])
    end
  end
end
