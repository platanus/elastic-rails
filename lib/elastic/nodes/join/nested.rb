module Elastic::Nodes
  class Nested < Base
    attr_accessor :path, :child

    def initialize(_path, _child)
      @path = _path
      @child = _child
    end

    def clone
      self.class.new @path, @child
    end

    def render
      {
        "nested" => {
          "path" => @path,
          "query" => @child.render
        }
      }
    end

    def simplify
      return self
    end
  end
end