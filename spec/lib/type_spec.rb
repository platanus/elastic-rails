require 'spec_helper'

describe Elastic::Type do
  let(:root_type) do
    Class.new(Struct.new(:id, :foo, :bar, :tags)) do
      def self.to_s
        'RootType'
      end
    end
  end

  let(:tag_type) do
    Class.new(Struct.new(:name))
  end

  let(:root_index) do
    Class.new(Elastic::Type) do
      def self.to_s
        'RootIndex'
      end

      def foo
        object.foo.split(' ')
      end
    end.tap do |index|
      index.target = root_type

      index.field :foo, type: :string
      index.field :bar, type: :long, transform: -> { self + 1 }

      index.nested :tags, using: tag_index
    end
  end

  let(:tag_index) do
    Class.new(Elastic::Type).tap do |index|
      index.field :name, type: :term
      index.target = tag_type
    end
  end

  let(:object) do
    tags = [ tag_type.new('baz_tag'), tag_type.new('qux_tag') ]
    root_type.new 1, 'hello world', 1, tags
  end

  describe "mapping" do
    it "freezes the underlying type definition on first call" do
      expect { root_index.mapping }.to change { root_index.definition.frozen? }.to true
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

  describe "definition" do
    it "holds the proper mapping structure" do
      expect(root_index.definition.as_es_mapping).to eq({
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
      })
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
  end
end