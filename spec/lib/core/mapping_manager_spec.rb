require 'spec_helper'

describe Elastic::Core::MappingManager do
  let(:client) { Elastic::Core::Adaptor.new 'suffix' }
  let(:index_name) { client.index_name }
  let(:targets) { ['type_a', 'type_b'] }

  def manager_w_definition(_options)
    described_class.new client, definition_double(_options.merge!(targets: targets))
  end

  let(:empty_mapping) do
    { 'properties' => {} }
  end

  let(:foo_mapping) do
    { 'properties' => { 'foo' => { 'type' => 'string', 'index' => 'not_analyzed' } } }
  end

  let(:bar_mapping) do
    {
      'properties' => {
        'bar' => {
          'type' => 'nested',
          'properties' => { 'baz' => { 'type' => 'long' } }
        }
      }
    }
  end

  let(:qux_mapping) do
    { 'properties' => { 'qux' => { 'type' => 'integer' } } }
  end

  let(:empty_manager) { manager_w_definition(mapping: empty_mapping) }
  let(:foo_manager) { manager_w_definition(mapping: foo_mapping) }
  let(:qux_manager) { manager_w_definition(mapping: qux_mapping) }

  context "index does not exist" do
    describe "fetch" do
      it { expect { foo_manager.fetch }.not_to raise_error }
    end

    describe "out_of_sync?" do
      it { expect(empty_manager.fetch.out_of_sync?).to be true }
      it { expect(foo_manager.fetch.out_of_sync?).to be true }
    end

    describe "migrate" do
      it "creates the index and the mapping" do
        expect { foo_manager.migrate }
          .to change { client.exists? && client.exists_mapping?('type_a') }.to(true)
      end
    end
  end

  context "mapping does not exist" do
    before { spec_es_client.indices.create index: index_name  }

    describe "fetch" do
      it { expect { foo_manager.fetch }.not_to raise_error }
    end

    describe "out_of_sync?" do
      it { expect(empty_manager.fetch.out_of_sync?).to be false }
      it { expect(foo_manager.fetch.out_of_sync?).to be true }
    end

    describe "migrate" do
      it "creates the mapping" do
        expect { foo_manager.migrate }.to change { client.exists_mapping?('type_a') }.to(true)
      end
    end
  end

  context "mapping already exists" do
    before do
      spec_es_client.indices.create index: index_name
      spec_es_client.indices.put_mapping index: index_name, type: 'type_a', body: foo_mapping
      spec_es_client.indices.put_mapping index: index_name, type: 'type_b', body: bar_mapping
      spec_es_client.indices.put_mapping index: index_name, type: 'type_c', body: qux_mapping
    end

    describe "fetch" do
      it { expect { foo_manager.fetch }.not_to raise_error }
    end

    describe "out_of_sync?" do
      let(:out_of_sync_manager) do
        manager_w_definition(mapping: { 'properties' => { 'foo' => { 'type' => 'string' } } })
      end

      it "returns true if user definition mapping is a subset of server mapping" do
        expect(empty_manager.fetch.out_of_sync?).to be false
        expect(foo_manager.fetch.out_of_sync?).to be false
        expect(out_of_sync_manager.fetch.out_of_sync?).to be true
        expect(qux_manager.fetch.out_of_sync?).to be true
      end
    end

    describe "incomplete?" do
      let(:complete_manager) do
        manager_w_definition(mapping: empty_mapping, fields: ['bar'])
      end

      let(:incomplete_manager) do
        manager_w_definition(mapping: empty_mapping, fields: ['baz'])
      end

      let(:incomplete_out_of_sync_manager) do
        manager_w_definition(
          mapping: { 'properties' => { 'foo' => { 'type' => 'string' } } },
          fields: ['baz']
        )
      end

      it "returns true if user definition contains fields not considered in server mapping" do
        expect(incomplete_manager.fetch.incomplete?).to be true
        expect(complete_manager.fetch.incomplete?).to be false
        expect(empty_manager.fetch.incomplete?).to be false
        expect(foo_manager.fetch.incomplete?).to be false
        expect(incomplete_out_of_sync_manager.fetch.incomplete?).to be false
      end
    end

    describe "has_field?" do
      before { foo_manager.fetch }

      it "returs true for fields contained in server's definition" do
        expect(foo_manager.has_field?('foo')).to be true
        expect(foo_manager.has_field?('baz')).to be false
      end

      it "handles nested fields properly" do
        expect(foo_manager.has_field?('bar.baz')).to be true
      end

      it "ignores fields that do not match the definition types" do
        expect(foo_manager.has_field?('qux')).to be false
      end
    end

    describe "get_field_options" do
      before { foo_manager.fetch }

      it "returs fields properties contained in server's definition" do
        expect(foo_manager.get_field_options('foo'))
          .to eq('type' => 'string', 'index' => 'not_analyzed')

        expect(foo_manager.get_field_options('bar')).to eq('type' => 'nested')
      end

      it "handles nested fields properly" do
        expect(foo_manager.get_field_options('bar.baz')).to eq('type' => 'long')
      end

      it "returns an empty hash for ignored or non existant fields" do
        expect(foo_manager.has_field?('qux')).to be false
        expect(foo_manager.has_field?('baz')).to be false
      end
    end

    describe "migrate" do
      let(:out_of_sync_manager) do
        manager_w_definition(mapping: { 'properties' => { 'baz' => { 'type' => 'string' } } }).fetch
      end

      it "changes mapping if there are no conflicts" do
        expect { out_of_sync_manager.migrate }
          .to change { out_of_sync_manager.get_field_options('baz') }
      end

      let(:conflicting_manager) do
        manager_w_definition(mapping: { 'properties' => { 'foo' => { 'type' => 'long' } } }).fetch
      end

      it "reindex if there are mapping conflicts", skip: true do
        expect { conflicting_manager.migrate }
          .to change { conflicting_manager.get_field_options('foo') }
      end
    end
  end
end
