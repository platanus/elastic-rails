require 'spec_helper'

describe Elastic::Core::SourceFormatter do
  let(:foo_field) { field_double 'foo' }
  let(:bar_field) { field_double 'bar' }
  let(:baz_field) { field_double 'baz' }

  let(:definition) { definition_double(fields: [foo_field, bar_field, baz_field]) }

  let(:formatter) { described_class.new definition }

  describe "format" do
    it "calls prepare_value_for_result on each named field ands return transformed hash" do
      expect(foo_field).to receive(:prepare_value_for_result).with(20).and_return(30)
      expect(bar_field).not_to receive(:prepare_value_for_result)
      expect(baz_field).to receive(:prepare_value_for_result).with(:baz).and_return(:baz)

      expect(formatter.format('foo' => 20, 'baz' => :baz, 'qux' => :nope))
        .to eq('foo' => 30, 'baz' => :baz, 'qux' => :nope)
    end
  end

  describe "format_field" do
    it "calls prepare_value_for_result on matching field" do
      expect(foo_field).to receive(:prepare_value_for_result).with(20).and_return(30)
      expect(bar_field).not_to receive(:prepare_value_for_result)
      expect(baz_field).not_to receive(:prepare_value_for_result)

      expect(formatter.format_field('foo', 20)).to eq 30
      expect(formatter.format_field('qux', 10)).to eq 10
    end
  end
end
