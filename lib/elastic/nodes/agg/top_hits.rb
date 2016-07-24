module Elastic::Nodes::Agg
  class TopHits < Elastic::Nodes::Base
    attr_accessor :size

    def source=(_values)
      case _values
      when nil, false
        @source = _values
      when Array, Enumerable
        @source = _values.dup.to_a
      else
        raise ArgumentError, 'invalid query source value'
      end
    end

    def render
      options = {}
      options['size'] = @size if @size
      options['_source'] = @source unless @source.nil?

      { 'top_hits' => options }
    end

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def handle_result(_raw)
      hits = _raw['hits'] ? _raw['hits']['hits'].map { |h| Elastic::Results::Hit.new h } : []
      Elastic::Results::HitCollection.new(hits)
    end

    private

    def prepare_clone(_clone)
      _clone.source = @source
      _clone.size = @size
      _clone
    end
  end
end
