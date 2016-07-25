module Elastic::Nodes
  class BaseAgg < Base
    attr_reader :name

    def self.build(_name)
      new.tap { |n| n.name = _name }
    end

    def initialize
      @name = 'default'
    end

    def name=(_value)
      @name = _value.to_s
    end

    def clone
      copy_name super
    end

    def simplify
      copy_name super
    end

    private

    def copy_name(_clone)
      _clone.name = @name
      _clone
    end
  end
end
