module Elastic::Nodes
  class Base
    def self.clone_with(&_block)
      clone_steps << _block
    end

    def self.simplify_with(&_block)
      simplify_steps << _block
    end

    def self.clone_and_simplify_with(&_block)
      clone_steps << _block
      simplify_steps << _block
    end

    def self.clone_steps
      @clone_steps ||= []
    end

    def self.simplify_steps
      @simplify_steps ||= []
    end

    def ==(_node)
      render == _node.render
    end

    def render
      raise NotImplementedError, 'render must be implemented by each node'
    end

    def clone
      self.class.new.tap do |new_node|
        self.class.clone_steps.each do |step|
          instance_exec(new_node, &step)
        end
      end
    end

    def simplify
      self.class.new.tap do |new_node|
        self.class.simplify_steps.each do |step|
          instance_exec(new_node, &step)
        end
      end
    end

    def handle_result(_raw)
      nil
    end

    private

    def base_clone
      self.class.new
    end
  end
end
