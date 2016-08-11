module Elastic::Nodes
  class TopHits < BaseAgg
    include Concerns::HitProvider

    def render(_options = {})
      hash = {}
      render_hit_options hash

      { 'top_hits' => hash }
    end

    def handle_result(_raw, _formatter)
      hits = _raw['hits'] ? prepare_hits(_raw['hits']['hits'], _formatter) : []
      Elastic::Results::HitCollection.new(hits)
    end
  end
end
