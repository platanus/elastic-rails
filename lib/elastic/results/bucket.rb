module Elastic::Results
  class Bucket < Aggregations
    attr_reader :key, :total

    def initialize(_key, _total, _aggs)
      @key = _key
      @total = _total
      super _aggs
    end

    def as_value
      # TODO: return aggregation value if configured as single bucket
      self
    end
  end
end
