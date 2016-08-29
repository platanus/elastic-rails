require 'spec_helper'

describe Elastic::Core::Connector do
  let(:api) { Elastic.config.api_client }

  let(:mapping) do
    {
      'properties' => {
        'foo' => { 'type' => 'string', 'index' => 'not_analyzed' },
        'bar' => { 'type' => 'integer' }
      }
    }
  end

  let(:connector) do
    described_class.new('idx_name', ['type_a', 'type_b'], mapping)
  end

  let(:index_name) { connector.index_name }

  let(:foo_record) { { id: 'foo', type: 'type_a', data: { 'foo' => 'qux', 'bar' => 1 } } }
  let(:bar_record) { { id: 'bar', type: 'type_a', data: { 'foo' => 'baz', 'bar' => 2 } } }
  let(:all_records) { [foo_record, bar_record] }

  context "when index does not exists" do
    describe "status" do
      it { expect(connector.status).to be :not_available }
    end

    describe "remap" do
      it "creates the new index with the provided mapping" do
        expect { connector.remap }
          .to change { api.indices.exists? index: index_name }.to true

        expect(es_index_mappings(index_name, 'type_a')).to eq mapping
        expect(es_index_mappings(index_name, 'type_b')).to eq mapping
      end
    end
  end

  context "when index already exists and mapping is empty" do
    before do
      prepare_index
    end

    describe "status" do
      it { expect(connector.status).to be :not_synchronized }
    end

    describe "remap" do
      it "updates index mappings" do
        expect { connector.remap }
          .to change { es_index_mappings(index_name, 'type_a') }.to mapping
      end
    end
  end

  context "when index already exists and mapping matches" do
    before do
      prepare_index mapping: mapping, records: all_records
    end

    describe "status" do
      it { expect(connector.status).to be :ready }
    end

    describe "index" do
      it "stores new documents" do
        expect do
          connector.index('_id' => 'qux', '_type' => 'type_a', 'data' => { foo: 'world' })
          api.indices.refresh index: index_name
        end.to change { es_index_count(index_name) }.by(1)
      end
    end

    describe "drop" do
      it "removes index" do
        expect { connector.drop }
          .to change { api.indices.exists? index: "#{index_name}:dummy" }.to false
      end
    end

    context "and some objects have already been indexed" do
      before do
        connector.index('_id' => 'foo', '_type' => 'type_a', 'data' => { foo: 'hello' })
        connector.index('_id' => 'bar', '_type' => 'type_a', 'data' => { foo: 'world' })
      end

      describe "delete" do
        it "removes existing documents from index" do
          expect do
            connector.delete('type_a', 'bar')
          end.to change { es_index_count(index_name) }.by(-1)
        end
      end
    end
  end

  context "when index already exists and mapping is not synchronized" do
    before do
      prepare_index(
        mapping: { 'properties' => { 'bar' => { 'type' => 'integer' } } }
      )
    end

    describe "status" do
      it { expect(connector.status).to be :not_synchronized }
    end

    describe "remap" do
      it "updates index mappings" do
        expect { connector.remap }
          .to change { es_index_mappings(index_name, 'type_a') }.to mapping
      end
    end
  end

  context "when index already exists and mapping cant be synchronized" do
    before do
      prepare_index(
        mapping: {
          'properties' => { 'foo' => { 'type' => 'string' }, 'bar' => { 'type' => 'integer' } }
        },
        records: all_records
      )
    end

    describe "status" do
      it { expect(connector.status).to be :not_synchronized }
    end

    describe "remap" do
      it "returns false" do
        expect(connector.remap).to be false
      end
    end

    describe "migrate" do
      it "regenerates index with new map and moves records to new index" do
        expect { connector.migrate }.to change { es_indexes_for_alias(index_name) }
        expect(es_index_mappings(index_name, 'type_a')).to eq mapping
        expect(es_index_count(index_name)).to eq 2
      end
    end
  end

  context "when rollover block is being called" do
    before { prepare_index mapping: mapping }

    describe "index" do
      it "makes stored document available only after block has finished" do
        connector.rollover do
          connector.index('_id' => 'foo', '_type' => 'type_a', 'data' => { foo: 'world' })

          api.indices.refresh index: index_name
          expect(es_index_count(index_name)).to eq 0
        end

        expect(es_index_count(index_name)).to eq 1
      end

      it "give docs indexed outside rollover higher priority than docs added by the rollover" do
        connector.rollover do
          Thread.new do
            connector.index('_id' => 'foo', '_type' => 'type_a', 'data' => { foo: 'outside' })
          end.join

          connector.index('_id' => 'foo', '_type' => 'type_a', 'data' => { foo: 'inside' })
        end

        expect(api.search(index: index_name)['hits']['hits'].first['_source'])
          .to eq('foo' => 'outside')
      end
    end
  end

  # Some helpers

  def prepare_index(mapping: nil, records: nil)
    actual_index = "#{index_name}:dummy"

    api.indices.create index: actual_index
    api.cluster.health wait_for_status: 'yellow'
    api.indices.put_alias index: actual_index, name: index_name
    api.indices.put_alias index: actual_index, name: "#{index_name}.w"

    if mapping
      api.indices.put_mapping index: actual_index, type: 'type_a', body: mapping
      api.indices.put_mapping index: actual_index, type: 'type_b', body: mapping
    end

    if records
      records.each do |r|
        api.index(index: actual_index, id: r[:id], type: r[:type], body: r[:data])
      end

      api.indices.refresh index: actual_index
    end
  end
end
