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
      base_clone.tap do |clone|
        clone.field = @field
        clone.missing = @missing
      end
    end

    def render
      options = { 'field' => @field.to_s }
      options['missing'] = @missing if @missing

      { metric => options }
    end

    def simplify
      clone
    end

    def handle_result(_raw)
      _raw['value']
    end

    private

    def metric
    end
  end
end
