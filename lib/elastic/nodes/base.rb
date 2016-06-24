module Elastic::Nodes
  class Base
    def ==(_node)
      render == _node.render
    end
  end
end
