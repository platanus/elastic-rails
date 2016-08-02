module Elastic::Results
  class Root < HitCollection
    attr_reader :aggregations, :total

    def initialize(_hits, _total, _aggs)
      super _hits
      @total = _total
      @aggregations = Aggregations.new _aggs
    end

    def traverse(&_block)
      super
      aggregations.traverse(&_block)
    end
  end
end
