module Elastic::Shims::Concerns
  module HitPicker
    def render
      set_hits_source unless required_source_fields.nil?
      super
    end

    def handle_result(_raw, _formatter)
      result = super

      case result
      when Elastic::Results::Root
        transform_collection(result)
      when Elastic::Results::GroupedResult
        result.map_to_group { |c| transform_collection(c) }
      else
        raise "unable to pick from result of type #{result.class}"
      end
    end

    private

    def set_hits_source
      child.pick(Elastic::Nodes::Concerns::HitProvider) do |node|
        node.source = required_source_fields
      end
    end

    def transform_collection(_collection)
      _collection.map_with_score { |h| pick_from_hit(h) }
    end

    def pick_from_hit(_hit)
      raise NotImplementedError, 'pick_from_hit not implemented'
    end

    def required_source_fields
      nil
    end
  end
end
