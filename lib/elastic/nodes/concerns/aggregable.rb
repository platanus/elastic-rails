module Elastic::Nodes::Concerns
  module Aggregable
    def has_aggregations?
      aggs.count > 0
    end

    def aggregations=(_aggs)
      @aggs = _aggs.dup.to_a
    end

    def aggregations
      @aggs.each
    end

    def aggregate(_node)
      raise ArgumentError, 'node must provide a name' unless _node.name
      aggs << _node
    end

    def traverse(&_block)
      super
      aggs.each { |a| a.traverse(&_block) }
    end

    def clone
      node = super
      node.aggregations = aggs.map(&:clone)
      node
    end

    def simplify
      node = super
      node.aggregations = aggs.map(&:simplify)
      node
    end

    private

    def aggs
      @aggs ||= []
    end

    def render_aggs(_into, _options)
      _into['aggs'] = Hash[aggs.map { |a| [a.name.to_s, a.render(_options)] }] if has_aggregations?
      _into
    end

    def load_aggs_results(_raw, _formatter)
      {}.tap do |result|
        aggs.each do |node|
          result[node.name] = node.handle_result(_raw[node.name.to_s], _formatter)
        end
      end
    end
  end
end
