module Elastic::Shims
  class SingleAggregation < Base
    def handle_result(_raw, _formatter)
      result = super

      case result
      when Elastic::Results::Root
        result.aggregations.first.last.as_value
      when Elastic::Results::GroupedResult
        result.map_to_group { |b| b.first.last }
      else
        raise "unable to reduce result of type #{result.class}"
      end
    end
  end
end
