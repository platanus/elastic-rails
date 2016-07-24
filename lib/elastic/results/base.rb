module Elastic::Results
  class Base
    include Elastic::Support::Traversable

    def as_value
      self
    end

    def traverse(&_block)
      _block.call(self)
    end
  end
end
