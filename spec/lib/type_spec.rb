require 'spec_helper'

describe Elastic::Type do
  let(:root_type) { build_type('RootType', :id, :foo, :bar, :tags) }
  let(:tag_type) { build_type('TagType', :name) }

  let(:root_index) do
    build_index('RootIndex', target: root_type) do
      field :foo, type: :text
      field :bar, type: :long, transform: -> { self + 1 }

      nested :tags do
        field :name, type: :term
      end

      def foo
        object.foo.split(' ')
      end
    end
  end

  let(:object) do
    tags = [tag_type.new('baz_tag'), tag_type.new('qux_tag')]
    root_type.new 1, 'hello world', 1, tags
  end

  describe "definition" do
    it "freezes the underlying type definition on first call" do
      expect { root_index.definition }.to change { root_index.pre_definition.frozen? }.to true
    end

    it "holds the proper mapping structure" do
      expect(root_index.definition.as_es_mapping).to eq(
        'properties' => {
          'foo' => { 'type' => 'text' },
          'bar' => { 'type' => 'long' },
          'tags' => {
            'type' => 'nested',
            'properties' => {
              'name' => { 'type' => 'keyword' }
            }
          }
        }
      )
    end
  end

  describe "as_elastic_document" do
    it "renders the document according the field definition" do
      expect(root_index.new(object).as_elastic_document).to eq(
        '_id' => 1,
        'data' => {
          "foo" => ['hello', 'world'],
          "bar" => 2,
          "tags" => [
            { "name" => "baz_tag" },
            { "name" => "qux_tag" }
          ]
        }
      )
    end
  end

  describe "delete" do
    it "calls connector.delete with object type and id" do
      object = root_type.new(2, 'hello world', 1, [])
      expect(root_index.connector).to receive(:delete)
        .with('_id' => 2).and_return nil
      root_index.delete(object)
    end

    it "fails if object does not provide an id" do
      object = root_type.new(nil, 'hello world', 1, [])
      expect { root_index.delete(object) }.to raise_error ArgumentError
    end
  end

  context "whiny_indices option is enabled" do
    before { allow(Elastic.config).to receive(:whiny_indices).and_return true }

    describe "index" do
      it "fails if mapping is out of sync" do
        expect { root_index.index(object) }.to raise_error RuntimeError
      end
    end

    describe "import" do
      it "fails if mapping is out of sync" do
        expect { root_index.import [object] }.to raise_error RuntimeError
      end
    end
  end

  context "mapping is synced" do
    before { root_index.migrate }

    describe "index" do
      it "stores the new document in index using the object id" do
        root_index.index(object)

        expect(es_find_by_id(root_index.index_name, object.id)).not_to be nil
      end
    end

    describe "import" do
      let(:objects) do
        [
          root_type.new(1, 'hello world', 1, []),
          root_type.new(2, 'hello world', 1, [])
        ]
      end

      it "stores a batch of objects" do
        expect { root_index.import(objects) }
          .to change { es_index_count(root_index.index_name) }.by 2
      end

      it "allows setting the batch size using the :batch_size option" do
        expect(Elastic::Commands::ImportIndexDocuments)
          .to receive(:for)
          .with(index: root_index, collection: [], batch_size: :foo)
          .and_return(nil)

        root_index.import [], batch_size: :foo
      end

      it "allows setting the batch size by setting the index import_batch_size property" do
        root_index.import_batch_size = :bar

        expect(Elastic::Commands::ImportIndexDocuments)
          .to receive(:for)
          .with(index: root_index, collection: [], batch_size: :bar)
          .and_return(nil)

        root_index.import []
      end

      it "allows setting the batch size by setting Configuration.import_batch_size property" do
        Elastic.configure(import_batch_size: :qux)

        expect(Elastic::Commands::ImportIndexDocuments)
          .to receive(:for)
          .with(index: root_index, collection: [], batch_size: :qux)
          .and_return(nil)

        root_index.import []
      end
    end

    describe "drop" do
      it "deletes the index" do
        expect { root_index.drop }
          .to change { es_index_exists?(root_index.index_name) }.to false
      end
    end
  end
end
