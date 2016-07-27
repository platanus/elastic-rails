module Elastic::Results
  class Root < HitCollection
    attr_reader :aggregations

    def initialize(_hits, _aggs)
      super _hits
      @aggregations = Aggregations.new _aggs
    end

    def traverse(&_block)
      super
      aggregations.traverse(&_block)
    end
  end
end
