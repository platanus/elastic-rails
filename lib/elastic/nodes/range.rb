module Elastic::Nodes
  class Range < Base
    include Concerns::Boostable

    attr_accessor :field, :gte, :gt, :lte, :lt

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def render(_options = {})
      hash = {}
      hash['gte'] = @gte unless @gte.nil?
      hash['gt'] = @gt unless @gt.nil?
      hash['lte'] = @lte unless @lte.nil?
      hash['lt'] = @lt unless @lt.nil?

      { "range" => { @field.to_s => render_boost(hash) } }
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
