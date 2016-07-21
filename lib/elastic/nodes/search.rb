module Elastic::Nodes
  class Search < Base
    include Aggregable

    clone_with { |c| prepare_clone(c, @query.clone) }

    simplify_with { |c| prepare_clone(c, @query.simplify) }

    attr_accessor :query, :size, :offset

    def self.build(_query)
      new.tap { |n| n.query = _query }
    end

    def initialize
      super
      @size = size || Elastic::Configuration.page_size
      @offset = offset
      @fields = nil
    end

    def fields
      return nil if @fields.nil?
      @fields.each
    end

    def fields=(_values)
      @fields = _values.nil? ? nil : _values.dup.to_a
    end

    def render
      {
        "size" => @size,
        "query" => @query.render
      }.tap do |options|
        options["_source"] = @fields unless @fields.nil?
        options["from"] = @offset unless offset == 0
        render_aggs(options)
      end
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
      _clone.fields = @fields
    end
  end
end
