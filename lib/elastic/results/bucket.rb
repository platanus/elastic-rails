module Elastic::Results
  class Bucket < Base
    attr_reader :key

    def initialize(_key, _aggs)
      @key = _key
      @aggs = _aggs
    end

    def [](_key)
      @aggs[_key.to_s].try(:as_value)
    end

    def aggs
      @aggs.each
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
