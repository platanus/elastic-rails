module Elastic::Results
  class Root < Base
    extend Forwardable
    include Enumerable

    def_delegators :@hits, :last, :first, :count, :[], :each

    def initialize(_hits, _aggs)
      @hits = _hits
      @aggs = _aggs
    end

    def [](_key)
      @aggs[_key.to_s]
    end

    def each_hits(&_block)
      @hits.each(&_block)
      @aggs.each_value { |a| a.each_hit(&_block) if a.is_a? Base }
    end
  end
end
