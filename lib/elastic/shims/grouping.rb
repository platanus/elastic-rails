module Elastic::Shims
  class Grouping < Base
    def handle_result(_raw, _formatter)
      chain = extract_aggregation_chain
      groups = group_recursive(super.aggregations, chain)
      Elastic::Results::GroupedResult.new chain, groups
    end

    private

    def extract_aggregation_chain
      child.pick(Elastic::Nodes::Concerns::Aggregable).map do |node|
        bucketed = node.aggregations.find { |n| n.is_a? Elastic::Nodes::Concerns::Bucketed }
        bucketed.try(:name)
      end.reject(&:nil?)
    end

    def group_recursive(_agg_context, _chain, _keys = {}, _groups = [], _idx = 0)
      if _idx < _chain.length
        name = _chain[_idx]
        agg = _agg_context[name] || []
        agg.each do |bucket|
          group_recursive(bucket, _chain, _keys.merge(name => bucket.key), _groups, _idx + 1)
        end
      else
        _groups << Elastic::Results::ResultGroup.new(_keys, _agg_context)
      end

      _groups
    end
  end
end
