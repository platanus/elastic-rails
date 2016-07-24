module Elastic::Nodes
  class Search < Base
    include Aggregable

    attr_accessor :query, :size, :offset

    def self.build(_query)
      new.tap { |n| n.query = _query }
    end

    def initialize
      super
      @size = size || Elastic::Configuration.page_size
      @offset = offset
      @source = nil
    end

    def source
      return nil if @source.nil?
      @source.each
    end

    def source=(_values)
      @source = _values.nil? ? nil : _values.dup.to_a
    end

    def traverse(&_block)
      super
      @query.traverse(&_block)
    end

    def render
      {
        "size" => @size,
        "query" => @query.render
      }.tap do |options|
        options["_source"] = @source unless @source.nil?
        options["from"] = @offset unless offset == 0
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
      _clone.size = @size
      _clone.offset = @offset
      _clone.source = @source
    end
  end
end
