module Elastic::Nodes
  class Search < Base
    include Aggregable
    include Concerns::HitProvider

    attr_accessor :query, :offset

    def self.build(_query)
      new.tap { |n| n.query = _query }
    end

    def initialize
      @size = Elastic::Configuration.page_size
      @offset = 0
    end

    def traverse(&_block)
      super
      @query.traverse(&_block)
    end

    def render
      { "query" => @query.render }.tap do |options|
        options["from"] = @offset unless offset == 0
        render_hit_options(options)
        render_aggs(options)
      end
    end

    def clone
      prepare_clone(super, @query.clone)
    end

    def simplify
      prepare_clone(super, @query.simplify)
    end

    def handle_result(_raw)
      hits = _raw['hits'] ? _raw['hits']['hits'].map { |h| Elastic::Results::Hit.new h } : []
      aggs = _raw['aggregations'] ? load_aggs_results(_raw['aggregations']) : {}

      Elastic::Results::Root.new(hits, aggs)
    end

    private

    def prepare_clone(_clone, _query)
      _clone.query = _query
      _clone.offset = @offset
    end
  end
end
