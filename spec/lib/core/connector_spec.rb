require 'spec_helper'

describe Elastic::Core::Connector do
  let(:api) { Elastic.config.api_client }

  let(:mapping) do
    {
      'properties' => {
        'foo' => { 'type' => 'keyword' },
        'bar' => { 'type' => 'integer' }
      }
    }
  end

  let(:connector) do
    described_class.new('idx_name', mapping, settling_time: 0.seconds)
  end

  let(:index_name) { connector.index_name }

  let(:foo_record) { { id: 'foo', data: { 'foo' => 'qux', 'bar' => 1 } } }
  let(:bar_record) { { id: 'bar', data: { 'foo' => 'baz', 'bar' => 2 } } }
  let(:all_records) { [foo_record, bar_record] }

  context "when index does not exists" do
    describe "status" do
      it { expect(connector.status).to be :not_available }
    end

    describe "remap" do
      it "creates the new index with the provided mapping" do
        expect { connector.remap }
          .to change { api.indices.exists? index: index_name }.to true
        expect(es_index_mapping(index_name)).to eq mapping
      end
    end

    describe "index" do
      it "fails with index missing error" do
        expect do
          connector.index('_id' => 'qux', '_type' => '_doc', 'data' => { foo: 'world' })
        end.to raise_error Elastic::MissingIndexError
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
          .to change { es_index_mapping(index_name) }.to mapping
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
          connector.index('_id' => 'qux', '_type' => '_doc', 'data' => { foo: 'world' })
          api.indices.refresh index: index_name
        end.to change { es_index_count(index_name) }.by(1)
      end
    end

    describe "drop" do
      it "removes index" do
        expect { connector.drop }
          .to change { api.indices.exists? index: "#{index_name}:12345" }.to false
      end
    end

    context "and some objects have already been indexed" do
      before do
        connector.index('_id' => 'foo', 'data' => { foo: 'hello' })
        connector.index('_id' => 'bar', 'data' => { foo: 'world' })
      end

      describe "delete" do
        it "removes existing documents from index" do
          expect { connector.delete('_id' => 'bar') }
            .to change { es_index_count(index_name) }.by(-1)
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
          .to change { es_index_mapping(index_name) }.to mapping
      end
    end
  end

  context "when index already exists and mapping cant be synchronized" do
    before do
      prepare_index(
        mapping: {
          'properties' => { 'foo' => { 'type' => 'text' }, 'bar' => { 'type' => 'integer' } }
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

        expect(es_index_mapping(index_name)).to eq mapping
        expect(es_index_count(index_name)).to eq 2
      end

      it "calls copy_to and does not overwrites documents changed during migration" do
        expect(connector).to receive(:copy_to).and_wrap_original do |m, *args|
          Thread.new do # inject insertion just before copy is initiated
            connector.index('_id' => 'foo', 'data' => { foo: 'inside' })
            connector.delete('_id' => 'bar')
          end.join

          m.call(*args)
        end

        connector.migrate
        expect(es_find_by_id(index_name, 'foo')['_source']).to eq('foo' => 'inside')
        expect(es_find_by_id(index_name, 'bar')).to be nil
      end
    end
  end

  context "when rollover block is being called" do
    before { prepare_index mapping: mapping }

    it "removes new index on failure" do
      rollover_index = nil

      expect do
        connector.rollover do |new_index|
          rollover_index = new_index
          raise "some error"
        end
      end.to raise_error RuntimeError

      expect(es_index_exists?(rollover_index)).to be false
    end

    describe "index" do
      it "makes documents indexed inside rollover block available only after block has finished" do
        connector.rollover do
          connector.index('_id' => 'foo', 'data' => { foo: 'world' })

          api.indices.refresh index: index_name
          expect(es_index_count(index_name)).to eq 0
        end

        expect(es_index_count(index_name)).to eq 1
      end

      it "makes documents indexed outside rollover block available inmediately" do
        connector.rollover do
          Thread.new do
            connector.index('_id' => 'foo', 'data' => { foo: 'world' })
            api.indices.refresh index: index_name
            expect(es_index_count(index_name)).to eq 1
          end.join
        end
      end

      it "executes index operations in the proper order independent of calling thread" do
        connector.rollover do
          connector.index('_id' => 'foo', 'data' => { foo: 'inside' })

          Thread.new do
            connector.index('_id' => 'foo', 'data' => { foo: 'outside' })
            connector.index('_id' => 'bar', 'data' => { foo: 'outside' })
          end.join

          connector.index('_id' => 'bar', 'data' => { foo: 'inside' })
        end

        api.indices.refresh(index: index_name)
        expect(es_find_by_id(index_name, 'foo')['_source']).to eq('foo' => 'outside')
        expect(es_find_by_id(index_name, 'bar')['_source']).to eq('foo' => 'inside')
      end
    end

    describe "delete" do
      it "removes existing documents from index" do
        connector.index('_id' => 'foo', 'data' => { foo: 'outside' })

        connector.rollover do
          connector.index('_id' => 'bar', 'data' => { foo: 'inside' })
          Thread.new do
            connector.delete('_id' => 'foo')
            connector.delete('_id' => 'bar')
          end.join
        end
        expect(es_index_count(index_name)).to be 0
      end
    end

    describe "rollover" do
      it "fails if called inside rollover" do
        connector.rollover do
          expect { connector.rollover {} }.to raise_error Elastic::RolloverError
        end
      end
    end
  end

  # Some helpers

  def prepare_index(mapping: nil, records: nil)
    actual_index = "#{index_name}:12345"

    api.indices.create index: actual_index
    api.cluster.health wait_for_status: 'yellow'
    api.indices.put_alias index: actual_index, name: index_name
    api.indices.put_alias index: actual_index, name: "#{index_name}.w"

    if mapping
      api.indices.put_mapping index: actual_index, type: '_doc', body: mapping
    end

    if records
      records.each do |r|
        api.index(index: actual_index, type: '_doc', id: r[:id], body: r[:data])
      end

      api.indices.refresh index: actual_index
    end
  end
end
