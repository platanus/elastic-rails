module Elastic::Nodes
  class TopHits < BaseAgg
    include Concerns::HitProvider

    def render
      options = {}
      render_hit_options options

      { 'top_hits' => options }
    end

    def handle_result(_raw, _formatter)
      hits = _raw['hits'] ? prepare_hits(_raw['hits']['hits'], _formatter) : []
      Elastic::Results::HitCollection.new(hits)
    end
  end
end
