module Elastic
  class Query
    extend Forwardable
    include Enumerable
    include Dsl::BoolQueryBuilder

    def_delegators :result, :ids, :pluck, :count, :[], :each, :each_with_score, :find_each,
      :as_es_query

    attr_reader :index, :root

    def initialize(_index, _root = nil, _extended_options = nil)
      @index = _index
      @root = _root || build_base_query
      @extended_options = _extended_options || HashWithIndifferentAccess.new
    end

    def coord_similarity(_enable)
      with_clone { root.query.disable_coord = !_enable }
    end

    def limit(_size)
      with_clone { root.page_size = _size }
    end
    alias :size :limit

    def offset(_offset)
      with_clone { root.offset = _offset }
    end

    def result(_reset = false)
      @result = nil if _reset
      @result ||= Core::Result.new(@index, @root.simplify.render, all_options)
    end

    private

    attr_reader :extended_options

    def with_clone(&_block)
      new_query = self.class.new(@index, @root.clone, extended_options.dup)
      new_query.instance_exec(&_block)
      new_query
    end

    def with_bool_query(&_block)
      with_clone { _block.call(root.query) }
    end

    def all_options
      @index.definition.extended_options.merge(extended_options).freeze
    end

    def build_base_query
      bool_query = Nodes::Boolean.new
      bool_query.disable_coord = true unless Configuration.coord_similarity
      Nodes::Search.build bool_query
    end
  end
end
