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

    def clone
      clone_with_children @children.map(&:clone)
    end

    def render
      {
        operation => @children.map(&:render)
      }
    end

    def simplify
      new_children = @children.map(&:simplify)

      nesting, non_nesting = new_children.partition { |n| n.is_a? Nested }
      if nesting.length > 1
        groups = Hash.new { |h,k| h[k] = [] }
        nesting.each { |n| groups[n.path] << n.child }
        nesting = groups.map do |path, nodes|
          next Nested.build(path, nodes.first) if nodes.length == 1
          Nested.build(path, clone_with_children(nodes))
        end
      end

      new_children = nesting + non_nesting
      return new_children.first if new_children.count == 1
      clone_with_children new_children
    end

    private

    def clone_with_children(_children)
      base_clone.tap do |clone|
        clone.children = _children
      end
    end

    def operation
      'and'
    end
  end
end