module Elastic::Shims
  class Base
    include Elastic::Support::Traversable

    attr_reader :child

    def initialize(_child)
      @child = _child
    end

    def traverse(&_block)
      @child.traverse(&_block)
    end

    def render
      @child.render
    end

    def handle_result(_raw, _formatter)
      @child.handle_result(_raw, _formatter)
    end
  end
end

require "elastic/shims/concerns/hit_picker"
