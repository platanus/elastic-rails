module Elastic::Nodes
  class Range < Base
    include Boostable

    attr_accessor :field, :gte, :gt, :lte, :lt

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def render
      options = {}
      options['gte'] = @gte unless @gte.nil?
      options['gt'] = @gt unless @gt.nil?
      options['lte'] = @lte unless @lte.nil?
      options['lt'] = @lt unless @lt.nil?

      { "range" => { @field.to_s => render_boost(options) } }
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.gte = @gte
      _clone.gt = @gt
      _clone.lte = @lte
      _clone.lt = @lt
      _clone
    end
  end
end
