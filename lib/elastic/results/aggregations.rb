module Elastic::Results
  class Aggregations < Base
    include Enumerable

    attr_reader :key

    def initialize(_aggs)
      @aggs = _aggs
    end

    def [](_key)
      @aggs[_key.to_sym].try(:as_value)
    end

    def each(&_block)
      @aggs.each(&_block)
    end

    def as_value
      # TODO: return aggregation value if configured as single bucket
      self
    end

    def traverse(&_block)
      super
      @aggs.each_value { |a| a.traverse(&_block) }
    end
  end
end
