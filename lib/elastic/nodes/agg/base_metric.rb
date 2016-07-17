module Elastic::Nodes::Agg
  class BaseMetric < Elastic::Nodes::Base
    def self.build(_field)
      new.tap { |m| m.field = _field }
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

    private

    def metric
    end
  end
end
