module Elastic::Nodes
  class Nested < Base
    def self.build(_path, _child)
      new.tap do |node|
        node.path = _path
        node.child = _child
      end
    end

    attr_accessor :path, :child

    def clone
      base_clone.tap do |clone|
        clone.path = @path
        clone.child = @child.clone
      end
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