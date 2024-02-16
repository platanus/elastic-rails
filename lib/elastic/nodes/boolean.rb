module Elastic::Nodes
  class Boolean < Base
    include Concerns::Boostable

    def self.build_and(_nodes)
      new.tap { |n| n.musts = _nodes }
    end

    def self.build_or(_nodes)
      new.tap { |n| n.shoulds = _nodes }
    end

    attr_accessor :minimum_should_match

    def initialize
      super
      @musts = []
      @must_nots = []
      @shoulds = []
      @filters = []
    end

    def must(_node)
      @musts << _node
    end

    def must_not(_node)
      @must_nots << _node
    end

    def should(_node)
      @shoulds << _node
    end

    def filter(_node)
      @filters << _node
    end

    def musts=(_nodes)
      @musts = _nodes.dup.to_a
    end

    def musts
      @musts.each
    end

    def must_nots=(_nodes)
      @must_nots = _nodes.dup.to_a
    end

    def must_nots
      @must_nots.each
    end

    def shoulds=(_nodes)
      @shoulds = _nodes.dup.to_a
    end

    def shoulds
      @shoulds.each
    end

    def filters=(_nodes)
      @filters = _nodes.dup.to_a
    end

    def filters
      @filters.each
    end

    def traverse(&_block)
      super
      @shoulds.each { |c| c.traverse(&_block) }
      @musts.each { |c| c.traverse(&_block) }
    end

    def render(_options = {})
      hash = {}
      hash['must'] = @musts.map { |n| n.render(_options) } if !@musts.empty?
      hash['must_not'] = @must_nots.map { |n| n.render(_options) } if !@must_nots.empty?
      hash['should'] = @shoulds.map { |n| n.render(_options) } if !@shoulds.empty?
      hash['filters'] = @filters.map { |n| n.render(_options) } if !@filters.empty?
      hash['minimum_should_match'] = minimum_should_match unless minimum_should_match.nil?
      render_boost(hash)

      { "bool" => hash }
    end

    def clone
      prepare_clone(
        super,
        @musts.map(&:clone),
        @must_nots.map(&:clone),
        @shoulds.map(&:clone),
        @filters.map(&:clone)
      )
    end

    def simplify
      new_must = @musts.map(&:simplify)
      new_must_not = @must_nots.map(&:simplify)
      new_should = @shoulds.map(&:simplify)
      new_filter = @filters.map(&:simplify)

      # TODO: detect must elements with boost = 0 and move them to "filter"

      total_nodes = new_must.length + new_must_not.length + new_should.length + new_filter.length
      if boost.nil? && total_nodes == 1
        return new_must.first if !new_must.empty?
        return new_should.first if !new_should.empty? # at least 1 should match
      end

      prepare_clone(super, new_must, new_must_not, new_should, new_filter)
    end

    private

    def prepare_clone(_clone, _musts, _must_nots, _shoulds, _filters)
      _clone.musts = _musts
      _clone.must_nots = _must_nots
      _clone.shoulds = _shoulds
      _clone.filters = _filters
      _clone.minimum_should_match = @minimum_should_match
      _clone
    end
  end
end
