module Elastic::Results
  class Bucket < Aggregations
    attr_reader :key

    def initialize(_key, _aggs)
      @key = _key
      super _aggs
    end

    def as_value
      # TODO: return aggregation value if configured as single bucket
      self
    end
  end
end
