module Elastic::Nodes
  class Range < Base
    attr_accessor :field, :gte, :gt, :lte, :lt

    def initialize(_field, gte: nil, gt: nil, lte: nil, lt: nil)
      @field = _field
      @gte = gte
      @gt = gt
      @lte = lte
      @lt = lt
    end

    def clone
      self.class.new @field, gte: @gte, gt: @gt, lte: @lte, lt: @lt
    end

    def render
      options = {}
      options['gte'] = @gte unless @gte.nil?
      options['gt'] = @gt unless @gt.nil?
      options['lte'] = @lte unless @lte.nil?
      options['lt'] = @lt unless @lt.nil?

      { "range" => { @field.to_s => options } }
    end

    def simplify
      return self
    end
  end
end
