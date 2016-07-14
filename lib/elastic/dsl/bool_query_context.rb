module Elastic::Dsl
  class BoolQueryContext
    include BoolQueryBuilder

    attr_reader :index

    def initialize(_index, _query, _modifier)
      @index = _index
      @wrapper = BoolQueryWrapper.new(_query, _modifier)
    end

    private

    def with_bool_query
      yield @wrapper
      self
    end

    class BoolQueryWrapper
      def initialize(_query, _modifier)
        @query = _query
        @modifier = _modifier
      end

      def must(_node)
        @query.must wrap(_node)
        self
      end

      def should(_node)
        @query.should wrap(_node)
        self
      end

      private

      def wrap(_query)
        @modifier.clone_with_query _query
      end
    end
  end
end
