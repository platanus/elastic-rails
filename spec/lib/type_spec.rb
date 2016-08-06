require 'spec_helper'

describe Elastic::Type do
  let(:root_type) { build_type('RootType', :id, :foo, :bar, :tags) }
  let(:tag_type) { build_type('TagType', :name) }

  let(:root_index) do
    build_index('RootIndex', target: root_type) do
      field :foo, type: :string
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
          'foo' => { 'type' => 'string' },
          'bar' => { 'type' => 'long' },
          'tags' => {
            'type' => 'nested',
            'properties' => {
              'name' => { 'type' => 'string', 'index' => 'not_analyzed' }
            }
          }
        }
      )
    end
  end

  describe "as_es_document" do
    it "renders the document according the field definition" do
      expect(root_index.new(object).as_es_document).to eq(
        '_type' => 'RootType',
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

  describe "save" do
    it "fails if mapping is out of sync" do
      expect { root_index.new(object).save }.to raise_error RuntimeError
    end
  end

  describe "import" do
    it "fails if mapping is out of sync" do
      expect { root_index.import [] }.to raise_error RuntimeError
    end
  end

  context "mapping is synced" do
    before { root_index.mapping.migrate }

    describe "save" do
      it "stores the new document in index using the object id" do
        root_index.new(object).save

        expect(root_index.adaptor.find(object.id, type: 'RootType')).not_to be nil
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
        expect { root_index.import(objects) }.to change { root_index.adaptor.refresh.count }.by 2
      end
    end

    describe "drop" do
      it "deletes the index" do
        expect { root_index.drop }.to change { root_index.adaptor.exists? }.to false
      end
    end
  end
end
