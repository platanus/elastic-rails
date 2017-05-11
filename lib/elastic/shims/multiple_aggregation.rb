module Elastic::Shims
  class MultipleAggregation < Base
    def handle_result(_raw, _formatter)
      result = super

      case result
      when Elastic::Results::Root
        result.aggregations
      when Elastic::Results::GroupedResult
        result
      else
        raise "unable to reduce result of type #{result.class}"
      end
    end
  end
end
