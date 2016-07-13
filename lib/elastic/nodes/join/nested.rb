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
      clone_with_child @child.clone
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
      clone_with_child @child.simplify
    end

    private

    def clone_with_child(_child)
      base_clone.tap do |clone|
        clone.path = @path
        clone.child = _child
      end
    end
  end
end
