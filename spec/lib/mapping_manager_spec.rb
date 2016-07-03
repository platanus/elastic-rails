require 'spec_helper'

describe Elastic::MappingManager do
  let(:client) { Elastic::Adaptor.new 'suffix' }
  let(:index_name) { client.index_name }
  let(:manager) { described_class.new client, ['type_a', 'type_b']  }

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

  let(:partial_foo_mapping) do
    { 'properties' => { 'foo' => { 'type' => 'string' } } }
  end

  context "index does not exist" do
    describe "fetch" do
      it { expect { manager.fetch }.not_to raise_error }
    end

    describe "synchronized?" do
      before { manager.fetch }
      it { expect(manager.synchronized?(empty_mapping)).to be false }
    end
  end

  context "mapping does not exist" do
    before { spec_es_client.indices.create index: index_name  }

    describe "fetch" do
      it { expect { manager.fetch }.not_to raise_error }
    end

    describe "synchronized?" do
      before { manager.fetch }
      it { expect(manager.synchronized?(empty_mapping)).to be true }
      it { expect(manager.synchronized?(foo_mapping)).to be false }
    end
  end

  context "a mapping already exists" do
    before do
      spec_es_client.indices.create index: index_name
      spec_es_client.indices.put_mapping index: index_name, type: 'type_a', body: foo_mapping
      spec_es_client.indices.put_mapping index: index_name, type: 'type_b', body: bar_mapping
      spec_es_client.indices.put_mapping index: index_name, type: 'type_c', body: qux_mapping
    end

    describe "fetch" do
      it { expect { manager.fetch }.not_to raise_error }
    end

    describe "synchronized?" do
      before { manager.fetch }
      it { expect(manager.synchronized?(empty_mapping)).to be true }
      it { expect(manager.synchronized?(foo_mapping)).to be true }
      it { expect(manager.synchronized?(bar_mapping)).to be true }
      it { expect(manager.synchronized?(partial_foo_mapping)).to be false }
      it { expect(manager.synchronized?(qux_mapping)).to be false }
    end

    describe "has_field?" do
      before { manager.fetch }
      it { expect(manager.has_field?('foo')).to be true }
      it { expect(manager.has_field?('bar.baz')).to be true }
      it { expect(manager.has_field?('qux')).to be false }
    end

    describe "get_field" do
      before { manager.fetch }
      it { expect(manager.get_field('foo')).to eq({ 'type' => 'string', 'index' => 'not_analyzed' }) }
      it { expect(manager.get_field('bar')).to eq({ 'type' => 'nested' }) }
      it { expect(manager.get_field('bar.baz')).to eq({ 'type' => 'long' }) }
      it { expect(manager['qux']).to eq({}) }
    end
  end
end