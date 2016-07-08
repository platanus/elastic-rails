module Elastic::Nodes
  class Base
    def ==(_node)
      render == _node.render
    end

    private

    def base_clone
      self.class.new
    end
  end
end
