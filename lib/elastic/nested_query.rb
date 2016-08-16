module Elastic
  class NestedQuery
    include Elastic::Dsl::BoolQueryBuilder

    attr_reader :index

    def initialize(_index, _root = nil)
      @index = _index
      @root = _root || build_root_node
    end

    def score_mode(_mode)
      with_clone { |root| root.score_mode = _mode }
    end

    def as_node
      @root.clone
    end

    private

    def with_clone(&_block)
      self.class.new @index, @root.clone.tap(&_block)
    end

    def with_bool_query(&_block)
      with_clone { |root| root.child.tap(&_block) }
    end

    def build_root_node
      Elastic::Nodes::Nested.build(nil, Elastic::Nodes::Boolean.new)
    end
  end
end
