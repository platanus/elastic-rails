module Elastic::Results
  class Root < HitCollection
    attr_reader :aggregations, :total, :scroll_id

    def initialize(_hits, _total, _aggs, _scroll_id)
      super _hits
      @total = _total
      @aggregations = Aggregations.new _aggs
      @scroll_id = _scroll_id
    end

    def traverse(&_block)
      super
      aggregations.traverse(&_block)
    end
  end
end
