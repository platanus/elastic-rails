module Elastic::Nodes
  class Range < BaseWithBoost
    attr_accessor :field, :gte, :gt, :lte, :lt

    def clone
      base_clone.tap do |clone|
        clone.field = @field
        clone.gte = @gte
        clone.gt = @gt
        clone.lte = @lte
        clone.lt = @lt
      end
    end

    def render
      options = {}
      options['gte'] = @gte unless @gte.nil?
      options['gt'] = @gt unless @gt.nil?
      options['lte'] = @lte unless @lte.nil?
      options['lt'] = @lt unless @lt.nil?

      { "range" => { @field.to_s => render_boost(options) } }
    end

    def simplify
      return self
    end
  end
end
