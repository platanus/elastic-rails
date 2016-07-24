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
      @aggs[_key.to_s].try(:as_value)
    end

    def aggs
      @aggs.each
    end

    def traverse(&_block)
      super
      @hits.each { |h| h.traverse(&_block) }
      @aggs.each_value { |a| a.traverse(&_block) }
    end
  end
end
