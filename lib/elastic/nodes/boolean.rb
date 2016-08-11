module Elastic::Nodes
  class Boolean < Base
    include Concerns::Boostable

    def self.build_and(_nodes)
      new.tap { |n| n.musts = _nodes }
    end

    def self.build_or(_nodes)
      new.tap { |n| n.shoulds = _nodes }
    end

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

    def render(_options = {})
      hash = {}
      hash['must'] = @musts.map { |n| n.render(_options) } if !@musts.empty?
      hash['should'] = @shoulds.map { |n| n.render(_options) } if !@shoulds.empty?
      hash['minimum_should_match'] = minimum_should_match unless minimum_should_match.nil?
      hash['disable_coord'] = true if disable_coord
      render_boost(hash)

      { "bool" => hash }
    end

    def clone
      prepare_clone super, @musts.map(&:clone), @shoulds.map(&:clone)
    end

    def simplify
      new_must = @musts.map(&:simplify)
      new_should = @shoulds.map(&:simplify)

      return new_must.first if new_must.length == 1 && new_should.empty?
      return new_should.first if new_should.length == 1 && new_must.empty? # at least 1 should match

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
