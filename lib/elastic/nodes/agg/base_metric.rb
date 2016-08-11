module Elastic::Nodes::Agg
  class BaseMetric < Elastic::Nodes::BaseAgg
    def self.build(_name, _field, missing: nil)
      super(_name).tap do |node|
        node.field = _field
        node.missing = missing
      end
    end

    attr_accessor :field, :missing

    def clone
      prepare_clone super
    end

    def simplify
      prepare_clone super
    end

    def render(_options = {})
      hash = { 'field' => @field.to_s }
      hash['missing'] = @missing if @missing

      { metric => hash }
    end

    def handle_result(_raw, _formatter)
      # TODO: apply formatter to value
      Elastic::Results::Metric.new _raw['value']
    end

    private

    def metric
    end

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.missing = @missing
      _clone
    end
  end
end
