module Elastic::Nodes
  class Boolean < Base
    include Concerns::Boostable

    attr_accessor :minimum_should_match, :disable_coord

    def initialize
      super
      @musts = []
      @shoulds = []
    end

    def must(_node)
      @musts << _node
    end

    def should(_node)
      @shoulds << _node
    end

    def musts=(_nodes)
      @musts = _nodes.dup.to_a
    end

    def musts
      @musts.each
    end

    def shoulds=(_nodes)
      @shoulds = _nodes.dup.to_a
    end

    def shoulds
      @shoulds.each
    end

    def traverse(&_block)
      super
      @shoulds.each { |c| c.traverse(&_block) }
      @musts.each { |c| c.traverse(&_block) }
    end

    def render
      options = {}.tap do |boolean|
        boolean['must'] = @musts.map(&:render) if !@musts.empty?
        boolean['should'] = @shoulds.map(&:render) if !@shoulds.empty?
        boolean['minimum_should_match'] = minimum_should_match unless minimum_should_match.nil?
        boolean['disable_coord'] = true if disable_coord
        render_boost(boolean)
      end

      { "bool" => options }
    end

    def clone
      prepare_clone super, @musts.map(&:clone), @shoulds.map(&:clone)
    end

    def simplify
      new_must = @musts.map(&:simplify)
      new_should = @shoulds.map(&:simplify)

      # TODO: ands inside must should be exploded (if no boost)
      # TODO: ors inside should should be exploded (if no boost)

      return new_must.first if new_must.length == 1 && new_should.empty?

      prepare_clone(super, new_must, new_should)
    end

    private

    def prepare_clone(_clone, _musts, _shoulds)
      _clone.musts = _musts
      _clone.shoulds = _shoulds
      _clone.minimum_should_match = @minimum_should_match
      _clone.disable_coord = @disable_coord
      _clone
    end
  end
end
