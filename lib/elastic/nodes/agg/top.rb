module Elastic::Nodes::Agg
  class Top < Elastic::Nodes::BaseAgg
    include Elastic::Nodes::Concerns::Sortable

    def self.build(_name, _field, _options = {})
      super(_name).tap do |node|
        node.field = _field
      end
    end

    attr_accessor :field

    def clone
      prepare_clone super
    end

    def simplify
      prepare_clone super
    end

    def render(_options = {})
      top_hit_config = { '_source' => { 'include' => [@field.to_s] }, 'size' => 1 }
      top_hit_config['sort'] = render_sorts if registered_sorts.count > 0

      { 'top_hits' => top_hit_config }
    end

    def handle_result(_raw, _formatter)
      raw_value = _raw['hits'] ? _raw['hits']['hits'].first['_source'][@field.to_s] : nil

      # TODO: apply formatter to value
      Elastic::Results::Metric.new raw_value
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone
    end
  end
end
