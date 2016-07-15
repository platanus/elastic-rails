require 'spec_helper'

describe Elastic::Core::Result do
  let(:ref_date) { Time.current.beginning_of_day }

  let(:root_type) { build_type('RootType', :id, :foo, :bar, :tags) }

  let(:tag_type) { build_type('TagType', :name) }

  let(:root_index) do
    build_index('RootIndex', target: root_type, migrate: true) do
      field :foo, type: :string
      field :bar, type: :long
      nested :tags do
        field :name, type: :term
      end
    end
  end

  def result(_query, _options = {})
    described_class.new(root_index, _query, _options)
  end

  context "some documents have been added (integration)" do
    before do
      tag_1 = tag_type.new('baz_tag')
      tag_2 = tag_type.new('qux_tag')
      root_index.index root_type.new(1, 'foo', 30, [tag_1])
      root_index.index root_type.new(2, 'bar', 20, [tag_2])
      root_index.index root_type.new(3, 'foo bar', 10, [tag_1, tag_2])
      root_index.refresh
    end

    describe "count" do
      it "returns the number of matching documents" do
        expect(result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } }).count).to eq(2)
      end
    end

    describe "each" do
      it "iterates over matching documents" do
        enum = result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } }).each
        expect(enum).to be_a Enumerator
        expect(enum.to_a.length).to eq 2
        expect(enum.to_a.first.foo).to eq 'foo'
        expect(enum.to_a.last.foo).to eq 'foo bar'
      end
    end

    describe "[]" do
      it "allow accessing results by index" do
        results = result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } })
        expect(results[0].foo).to eq 'foo'
        expect(results[1].foo).to eq 'foo bar'
      end
    end

    describe "ids" do
      it "returns the matching objecs ids" do
        expect(result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } }).ids)
          .to eq [1, 3]
      end
    end

    describe "pluck" do
      it "returns the required fields for matching documents" do
        expect(result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } }).pluck(:bar))
          .to include(30, 10)

        expect(result('query' => { 'match' => { 'foo' => { 'query' => 'foo' } } }).pluck(:foo))
          .to include('foo', 'foo bar')
      end
    end

    describe "each_with_score" do
      it "iterates over matching documents and its scores" do
        results = result(
          'query' => {
            'bool' => {
              'disable_coord' => true,
              'should' => [
                {
                  'function_score' => {
                    'weight' => 2.0,
                    'boost_mode' => 'replace',
                    'query' => {
                      'nested' => {
                        'path' => 'tags',
                        'query' => { 'term' => { 'tags.name' => 'baz_tag' } }
                      }
                    }
                  }
                },
                {
                  'function_score' => {
                    'weight' => 3.0,
                    'boost_mode' => 'replace',
                    'query' => {
                      'nested' => {
                        'path' => 'tags',
                        'query' => { 'term' => { 'tags.name' => 'qux_tag' } }
                      }
                    }
                  }
                }
              ]
            }
          }
        ).each_with_score.to_a

        expect(results[0][1]).to eq 5.0
        expect(results[0][0].foo).to eq 'foo bar'
        expect(results[1][1]).to eq 3.0
        expect(results[1][0].foo).to eq 'bar'
        expect(results[2][1]).to eq 2.0
        expect(results[2][0].foo).to eq 'foo'
      end
    end
  end
end
