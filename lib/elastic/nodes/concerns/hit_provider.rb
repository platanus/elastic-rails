module Elastic::Nodes::Concerns
  module HitProvider
    attr_accessor :size
    attr_reader :source

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

    def clone
      copy_hit_options super
    end

    def simplify
      copy_hit_options super
    end

    private

    def prepare_hits(_hits, _formatter)
      _hits.map do |raw_hit|
        Elastic::Results::Hit.new(
          raw_hit['_type'],
          raw_hit['_id'],
          raw_hit['_score'],
          raw_hit['_source'] ? _formatter.format(raw_hit['_source']) : nil
        )
      end
    end

    def copy_hit_options(_clone)
      _clone.size = @size
      _clone.source = @source
      _clone
    end

    def render_hit_options(_hash)
      _hash['size'] = @size unless @size.nil?
      _hash["_source"] = @source unless @source.nil?
      _hash
    end
  end
end
