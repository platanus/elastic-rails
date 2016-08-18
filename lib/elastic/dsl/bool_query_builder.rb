module Elastic::Dsl
  module BoolQueryBuilder
    def coord_similarity(_enable)
      with_bool_query { |query| query.disable_coord = !_enable }
    end

    def must(*_queries)
      with_bool_query do |query|
        query.must build_query_from_params(_queries)
      end
    end

    def must_not(*_queries)
      with_bool_query do |query|
        query.must_not build_query_from_params(_queries)
      end
    end

    def should(*_queries)
      with_bool_query do |query|
        query.should build_query_from_params(_queries)
      end
    end

    def with(_modifier, &_block)
      raise ArgumentError, 'block missing' if _block.nil?
      raise ArgumentError, 'node is not a modifier' unless _modifier.respond_to? :clone_with_query

      with_bool_query do |query|
        ctx = BoolQueryContext.new index, query, _modifier
        ctx.instance_exec(&_block)
        ctx
      end
    end

    def boost(_amount = nil, field: nil, fixed: false, factor: 1, modifier: :none, missing: 1,
      &_block)
      raise ArgumentError, 'must provide at least a boost amount' if _amount.nil? && field.nil?

      node = Elastic::Nodes::FunctionScore.new
      node.boost_mode = :replace if fixed

      if !field.nil?
        node.add_field_function(field, factor: factor, modifier: modifier, missing: missing)
      elsif fixed
        node.add_weight_function(_amount)
      else
        node.boost = _amount
      end

      # TODO: add decay function support.

      with(node, &_block)
    end

    private

    def build_query_from_params(_params)
      Elastic::Commands::BuildQueryFromParams.for(index: index, params: _params)
    end
  end
end
