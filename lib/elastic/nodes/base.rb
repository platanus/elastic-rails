module Elastic::Nodes
  class Base
    def ==(_node)
      render == _node.render
    end

    def render
      raise NotImplementedError, 'render must be implemented by each node'
    end

    def clone
      self.class.new
    end

    def simplify
      self.class.new
    end

    def handle_result(_raw)
      nil
    end
  end
end
