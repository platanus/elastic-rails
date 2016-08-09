module Elastic::Nodes::Concerns
  module Aggregable
    def has_aggs?
      aggs.count > 0
    end

    def aggs=(_aggs)
      @aggs = _aggs.dup.to_a
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
      node.aggs = aggs.map(&:clone)
      node
    end

    def simplify
      node = super
      node.aggs = aggs.map(&:simplify)
      node
    end

    private

    def aggs
      @aggs ||= []
    end

    def render_aggs(_into)
      _into['aggs'] = Hash[aggs.map { |a| [a.name.to_s, a.render] }] if has_aggs?
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
