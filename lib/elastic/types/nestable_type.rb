module Elastic::Types
  module NestableType
    def nested(_name, using: nil, &_block)
      using = Class.new(Elastic::NestedType, &_block) unless _block.nil?
      using = (_name + '_index').camelize.constantize if using.nil?

      definition.register_field Elastic::Fields::Nested.new(_name, using)
    end
  end
end