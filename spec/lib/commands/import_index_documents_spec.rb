require 'spec_helper'

describe Elastic::Commands::ImportIndexDocuments do
  let(:foo_type) { build_type('FooType', :id, :name) }

  let!(:foo_index) do
    build_index('FooIndex', target: foo_type, migrate: true) do
      field :name, type: :string
    end
  end

  let(:collection) { [foo_type.new(1, 'hello'), foo_type.new(2, 'world')] }

  def perform(_collection = nil)
    described_class.for(index: foo_index, collection: _collection)
  end

  before do
    allow(foo_type).to receive(:collect_for_elastic).and_yield(foo_type.new(1, 'hello'))
  end

  it "calls collect_for_elastic with nil if no collection is given" do
    expect(foo_type).to receive(:collect_for_elastic).with(foo_index.definition)
    perform
  end

  it "calls collect_for_elastic with collection if collection is given" do
    expect(foo_type).to receive(:collect_for_elastic).with(foo_index.definition, collection)
    perform collection
  end

  it "indexes returned documents" do
    expect { perform }.to change { foo_index.adaptor.refresh.count(type: 'FooType') }.by(1)
  end
end
