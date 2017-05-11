module Elastic::Dsl
  class ResultComposer
    include MetricBuilder

    def initialize(_aggs)
      @aggs = _aggs
    end

    def aggregate(_node)
      raise ArgumentError, 'node must provide a name' unless _node.name
      @aggs << _node
      nil
    end
  end
end
