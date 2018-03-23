require 'spec_helper'

describe Elastic::Query do
  let(:root_type) { build_type('RootType', :id, :foo, :bar, :tags) }

  let(:tag_type) { build_type('TagType', :name) }

  let(:root_index) do
    build_index('RootIndex', target: root_type, migrate: true) do
      field :id, type: :long
      field :foo, type: :text, fielddata: true
      field :bar, type: :long
      nested :tags do
        field :name, type: :term
      end
    end
  end

  let(:query) { described_class.new(root_index) }

  # TODO: put this spec in the bool_query_builder spec
  describe "should" do
    it "returns a new query" do
      expect(query.should(foo: 'teapot')).not_to be query
    end

    it "fails if given field name is not defined" do
      expect { query.should(teampot: 'foo') }.to raise_error ArgumentError
    end

    it "adds a new 'should' query element" do
      new_query = query.should(foo: 'teapot')
      expect(new_query.as_es_query).to eq(
        "query" => { "term" => { "foo" => { "value" => "teapot" } } },
        "size" => 20
      )
    end
  end

  # TODO: put this spec in the bool_query_builder spec
  describe "must" do
    it "returns a new query" do
      expect(query.must(foo: 'teapot')).not_to be query
    end

    it "adds a new must query element" do
      new_query = query.must(bar: 20)
      expect(new_query.as_es_query).to eq(
        "query" => { "term" => { "bar" => { "value" => 20 } } },
        "size" => 20
      )
    end
  end

  # TODO: put this spec in the bool_query_builder spec
  describe "boost" do
    it "returns a new query" do
      expect(query.boost(2.0) { must(bar: 20) }).not_to be query
    end

    it "adds the proper query element wrapped in a function score node" do
      new_query = query.boost(2.0) { must(bar: 20).should(foo: 'teapot') }

      expect(new_query.as_es_query).to eq(
        "query" => {
          "bool" => {
            "must" => [
              { "term" => { "bar" => { "value" => 20, "boost" => 2.0 } } }
            ],
            "should" => [
              { "term" => { "foo" => { "value" => "teapot", "boost" => 2.0 } } }
            ]
          }
        },
        "size" => 20
      )
    end
  end

  describe "as_query_node" do
    it "returns the underlying boolean node" do
      expect(query.as_query_node).to be_a Elastic::Nodes::Boolean
    end
  end

  context "some documents have been added (integration)" do
    before do
      tag_1 = tag_type.new('baz_tag')
      tag_2 = tag_type.new('qux_tag')
      root_index.index root_type.new(1, 'foo', 30, [tag_1])
      root_index.index root_type.new(2, 'bar', 20, [tag_2])
      root_index.index root_type.new(3, 'foo bar', 20, [tag_1, tag_2])
      root_index.refresh
    end

    describe "limit" do
      it "limits returned results" do
        enum = query.sort(:id).limit(1).each
        expect(enum).to be_a Enumerator
        expect(enum.to_a.length).to eq 1
        expect(enum.to_a.first.id).to eq 1
      end
    end

    describe "offset" do
      it "offset returned results" do
        enum = query.sort(:id).offset(1).each
        expect(enum).to be_a Enumerator
        expect(enum.to_a.length).to eq 2
        expect(enum.to_a.first.id).to eq 2
      end
    end

    describe "each" do
      it "iterates over matching documents" do
        enum = query.must(foo: 'foo').each
        expect(enum).to be_a Enumerator
        expect(enum.to_a.length).to eq 2
        expect(enum.to_a.first.foo).to eq 'foo'
        expect(enum.to_a.last.foo).to eq 'foo bar'
      end
    end

    describe "[]" do
      it "allow accessing results by index" do
        results = query.must(foo: 'foo')
        expect(results[0].foo).to eq 'foo'
        expect(results[1].foo).to eq 'foo bar'
      end
    end

    describe "sort" do
      it "changes the way returned results are ordered" do
        expect(query.sort(:foo).to_a.first.id).to be 2
        expect(query.sort(foo: :desc).to_a.first.id).to be 1
      end
    end

    describe "each_with_score" do
      it "iterates over matching documents and its scores" do
        results = query
                  .coord_similarity(false)
                  .boost(2.0, fixed: true) { should('tags.name' => 'baz_tag') }
                  .boost(3.0, fixed: true) { should('tags.name' => 'qux_tag') }

        results = results.each_with_score.to_a

        expect(results[0][1]).to eq 5.0
        expect(results[0][0].foo).to eq 'foo bar'
        expect(results[1][1]).to eq 3.0
        expect(results[1][0].foo).to eq 'bar'
        expect(results[2][1]).to eq 2.0
        expect(results[2][0].foo).to eq 'foo'
      end
    end

    describe "ids" do
      it "returns a scored id collection" do
        collection = query.must(foo: 'foo').ids

        expect(collection).to be_a Elastic::Results::ScoredCollection
        expect(collection.count).to eq 2
        expect(collection.to_a).to eq ["1", "3"]
      end
    end

    describe "pick" do
      it "returns a scored field collection" do
        collection = query.must(foo: 'foo').pick :foo

        expect(collection).to be_a Elastic::Results::ScoredCollection
        expect(collection.count).to eq 2
        expect(collection.to_a).to eq ["foo", "foo bar"]
      end
    end

    describe "total" do
      it "returns the matching document count" do
        expect(query.must(foo: 'foo').total).to eq 2
      end
    end

    describe "various metrics" do
      it "returns the required metric" do
        new_query = query.should('tags.name' => 'baz_tag')
        expect(new_query.average(:bar)).to eq 25
        expect(new_query.maximum(:bar)).to eq 30
        expect(new_query.minimum(:bar)).to eq 20
      end
    end

    describe "segment" do
      it "separates results in groups" do
        groups = query.segment(:bar)
        expect(groups.count).to eq 2
        expect(groups.result).to be_a Elastic::Results::GroupedResult

        keys_1, hits_1 = groups.first
        keys_2, hits_2 = groups.last

        expect(keys_1[:bar]).to eq 20
        expect(hits_1.count).to eq 2
        expect(hits_1[0].id).to eq 2
        expect(hits_1[1].id).to eq 3

        expect(keys_2[:bar]).to eq 30
        expect(hits_2.count).to eq 1
        expect(hits_2[0].id).to eq 1
      end
    end

    context "and query is segmented" do
      let!(:grouped) { query.segment(:bar) }

      describe "ids" do
        it "returns grouped id collections" do
          expect(grouped.ids).to be_a Elastic::Results::GroupedResult
          expect(grouped.ids.each_group.map(&:as_value).map(&:to_a)).to eq [["2", "3"], ["1"]]
        end
      end

      describe "[]" do
        it "allow accessing results by key" do
          expect(grouped[20].count).to eq 2
          expect(grouped[30].count).to eq 1
          expect(grouped[bar: 30].count).to eq 1
        end

        it "requires explicit key names if more than one segmentation is performed" do
          new_query = grouped.segment(:foo)
          expect { new_query[20] }.to raise_error ArgumentError
          expect(new_query[bar: 20, foo: 'foo'].count).to eq(1)
        end

        it "allows any key order if more than one segmentation is performed" do
          new_query = grouped.segment(:foo)
          expect(new_query[bar: 20, foo: 'bar'].count).to eq(2)
          expect(new_query[foo: 'bar', bar: 20].count).to eq(2)
        end
      end

      describe "pick" do
        it "returns grouped field collections" do
          expect(grouped.pick(:foo)).to be_a Elastic::Results::GroupedResult
          expect(grouped.pick(:foo).each_group.map(&:as_value).map(&:to_a))
            .to eq [["bar", "foo bar"], ["foo"]]
        end
      end

      describe "total" do
        it "it returns a grouped count metrics" do
          expect(grouped.total).to be_a Elastic::Results::GroupedResult
          expect(grouped.total.each_group.map(&:as_value)).to eq [2, 1]
        end
      end
    end
  end
end
