module Elastic::Results
  class Bucket < Base
    attr_reader :key

    def initialize(_key, _aggs)
      @key = _key
      @aggs = _aggs
    end

    def [](_key)
      @aggs[_key.to_s]
    end

    def each_hit(&_block)
      @aggs.each_value { |a| a.each_hit(&_block) if a.is_a? Base }
    end
  end
end
