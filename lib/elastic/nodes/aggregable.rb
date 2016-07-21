module Elastic::Nodes
  module Aggregable
    def self.included(_klass)
      _klass.clone_with { |c| c.aggs = Hash[aggs.map { |k, v| [k, v.clone] }] }
      _klass.simplify_with { |c| c.aggs = Hash[aggs.map { |k, v| [k, v.simplify] }] }
    end

    def has_aggs?
      aggs.count > 0
    end

    def aggs=(_aggs)
      @aggs = _aggs.dup
    end

    def aggregate(_name, _node)
      aggs[_name.to_s] = _node
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
