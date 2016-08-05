module Elastic::Shims
  class Grouping < Base
    def handle_result(_raw, _formatter)
      groups = []
      group_recursive(super.aggregations, HashWithIndifferentAccess.new, groups)
      Elastic::Results::GroupedResult.new groups
    end

    private

    def group_recursive(_agg_context, _keys, _groups)
      name, agg = _agg_context.first

      if agg.is_a? Elastic::Results::BucketCollection
        agg.each do |bucket|
          group_recursive(bucket, _keys.merge(name => bucket.key), _groups)
        end
      else
        _groups << Elastic::Results::ResultGroup.new(_keys, _agg_context)
      end
    end
  end
end
