module Elastic::Nodes
  class Base
    include Elastic::Support::Traversable

    def ==(_node)
      render == _node.render
    end

    def traverse(&_block)
      _block.call(self)
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

require "elastic/nodes/concerns/hit_provider"
