module Elastic
  class NestedQuery
    include Elastic::Dsl::BoolQueryBuilder

    attr_reader :index

    def initialize(_index, _node = nil)
      @index = _index
      @node = _node || Elastic::Nodes::Boolean.new
    end

    def as_query_node
      @node.clone
    end

    def as_es_query
      @node.render
    end

    private

    def with_bool_query(&_block)
      new_node = @node.clone.tap(&_block)
      self.class.new(@index, new_node)
    end
  end
end
