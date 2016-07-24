module Elastic::Nodes::Agg
  class BaseMetric < Elastic::Nodes::Base
    def self.build(_field, missing: nil)
      new.tap do |node|
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

    def render
      options = { 'field' => @field.to_s }
      options['missing'] = @missing if @missing

      { metric => options }
    end

    def handle_result(_raw)
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
