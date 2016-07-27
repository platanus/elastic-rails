module Elastic::Shims
  class Reducing < Base
    def handle_result(_raw)
      result = super

      case result
      when Elastic::Results::Root
        result.aggregations.first.last.as_value
      when Elastic::Results::GroupedResult
        groups = result.map do |keys, bucket|
          Elastic::Results::ResultGroup.new keys, bucket.first.last
        end

        Elastic::Results::GroupedResult.new groups
      else
        result
      end
    end
  end
end
