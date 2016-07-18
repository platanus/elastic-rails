module Elastic::Nodes
  class Range < Base
    include Boostable

    clone_and_simplify_with do |clone|
      clone.field = @field
      clone.gte = @gte
      clone.gt = @gt
      clone.lte = @lte
      clone.lt = @lt
    end

    attr_accessor :field, :gte, :gt, :lte, :lt

    def render
      options = {}
      options['gte'] = @gte unless @gte.nil?
      options['gt'] = @gt unless @gt.nil?
      options['lte'] = @lte unless @lte.nil?
      options['lt'] = @lt unless @lt.nil?

      { "range" => { @field.to_s => render_boost(options) } }
    end
  end
end
