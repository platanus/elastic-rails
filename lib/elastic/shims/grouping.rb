module Elastic::Shims
  class Grouping
    def initialize(_child)
      @child = _child
    end

    def render
      @child.render
    end

    def handle_result(_raw)
      result = @child.handle_result(_raw)
      Elastic::Results::GroupedResult.new group_recursive(result.aggregations, {}, [])
    end

    private

    def group_recursive(_agg_context, _keys, _result)
      name, agg = _agg_context.first

      if agg.is_a? Elastic::Results::BucketCollection
        agg.each do |bucket|
          group_recursive(bucket, _keys.merge(name => bucket.key), _result)
        end
      else
        _result << Elastic::Results::GroupedBucket.new(_keys, _agg_context)
      end

      _result
    end
  end
end
