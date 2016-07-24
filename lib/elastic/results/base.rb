module Elastic::Results
  class Base
    include Elastic::Support::Traversable

    def traverse(&_block)
      _block.call(self)
    end
  end
end
