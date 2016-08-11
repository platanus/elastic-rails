module Elastic::Nodes
  class And < Base
    def self.build(_children)
      new.tap { |node| node.children = _children }
    end

    def add_child(_child)
      @children << _child
    end

    def children=(_value)
      @children = _value.dup.to_a
    end

    def traverse(&_block)
      super
      @children.each { |c| c.traverse(&_block) }
    end

    def clone
      prepare_clone super, @children.map(&:clone)
    end

    def simplify
      new_children = @children.map(&:simplify)
      return new_children.first if new_children.count == 1
      prepare_clone(super, new_children)
    end

    def render(_options = {})
      { operation => @children.map { |c| c.render(_options) } }
    end

    private

    def prepare_clone(_clone, _children)
      _clone.children = _children
      _clone
    end

    def operation
      'and'
    end
  end
end
