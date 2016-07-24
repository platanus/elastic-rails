module Elastic::Nodes
  class Nested < Base
    def self.build(_path, _child)
      new.tap do |node|
        node.path = _path
        node.child = _child
      end
    end

    attr_accessor :path, :child

    def traverse(&_block)
      super
      @child.traverse(&_block)
    end

    def clone
      prepare_clone super, @child.clone
    end

    def simplify
      prepare_clone super, @child.simplify
    end

    def render
      {
        "nested" => {
          "path" => @path,
          "query" => @child.render
        }
      }
    end

    private

    def prepare_clone(_clone, _child)
      _clone.path = @path
      _clone.child = _child
      _clone
    end
  end
end
