module Elastic::Nodes
  module Aggregable
    def has_aggs?
      aggs.count > 0
    end

    def aggs=(_aggs)
      @aggs = _aggs.dup
    end

    def aggregate(_name, _node)
      aggs[_name.to_s] = _node
    end

    def traverse(&_block)
      super
      aggs.each_value { |a| a.traverse(&_block) }
    end

    def clone
      node = super
      node.aggs = Hash[aggs.map { |k, v| [k, v.clone] }]
      node
    end

    def simplify
      node = super
      node.aggs = Hash[aggs.map { |k, v| [k, v.simplify] }]
      node
    end

    private

    def aggs
      @aggs ||= {}
    end

    def render_aggs(_into)
      _into['aggs'] = Hash[aggs.map { |k, v| [k, v.render] }] if has_aggs?
      _into
    end

    def load_aggs_results(_raw)
      {}.tap do |result|
        aggs.each do |name, node|
          result[name] = node.handle_result(_raw[name])
        end
      end
    end
  end
end
