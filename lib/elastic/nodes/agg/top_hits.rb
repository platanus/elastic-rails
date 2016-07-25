module Elastic::Nodes
  class TopHits < BaseAgg
    include Concerns::HitProvider

    def render
      options = {}
      render_hit_options options

      { 'top_hits' => options }
    end

    def handle_result(_raw)
      hits = _raw['hits'] ? _raw['hits']['hits'].map { |h| Elastic::Results::Hit.new h } : []
      Elastic::Results::HitCollection.new(hits)
    end
  end
end
