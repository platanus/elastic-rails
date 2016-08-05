module Elastic::Shims
  class TotalPicking < Base
    def handle_result(_raw, _formatter)
      result = super

      case result
      when Elastic::Results::Root
        result.total
      when Elastic::Results::GroupedResult
        result.map_to_group { |bucket| Elastic::Results::Metric.new(bucket.total) }
      else
        raise "unable to pick from result of type #{result.class}"
      end
    end
  end
end
