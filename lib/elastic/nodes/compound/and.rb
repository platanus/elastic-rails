module Elastic::Nodes
  class And < Base
    attr_reader :children

    def initialize(_children)
      @children = _children
    end

    def clone
      self.class.new _children.map(&:clone)
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
          next Nested.new(path, nodes.first) if nodes.length == 1
          Nested.new(path, self.class.new(nodes))
        end
      end

      new_children = nesting + non_nesting
      return new_children.first if new_children.count == 1
      self.class.new new_children
    end

    private

    def operation
      'and'
    end
  end
end