module Elastic
  class Query
    include Capabilities::ContextHandler
    include Capabilities::BoolQueryBuilder
    include Capabilities::AggregationBuilder

    attr_accessor :type, :size, :input_transform

    def initialize(_type, minimum_should_match: 1, size: nil)
      @type = _type
      @size = size
      self.minimum_should_match = minimum_should_match
    end

    def render
      search = {}
      search['size'] = @size unless @size.nil?
      render_query_to search
      render_aggregations_to search
      search
    end

    def run
      type.query(render)
    end

    private

    def render_query_to(_search)
      query = {}
      render_bool_query_to query
      _search['query'] = query if query.length > 0
    end

    def transform_input(_name, _value)
      type.prepare_field_for_query _name, _value
    end
  end
end
