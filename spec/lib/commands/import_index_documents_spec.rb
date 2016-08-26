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
    allow(foo_type).to receive(:find_each_for_elastic).and_yield(foo_type.new(1, 'hello'))
  end

  it "calls find_each_for_elastic with nil if no collection is given" do
    expect(foo_type).to receive(:find_each_for_elastic).with no_args
    perform
  end

  it "calls collection.each if collection is given" do
    expect { perform(collection) }
      .to change { es_index_count(foo_index.es_index_name, type: 'FooType') }.by(2)
  end

  it "indexes returned documents" do
    expect { perform }
      .to change { es_index_count(foo_index.es_index_name, type: 'FooType') }.by(1)
  end
end
