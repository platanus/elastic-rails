module Elastic::Types
  module NestableType
    def nested(_name, using: nil, target: nil, &_block)
      unless _block.nil?
        using = Class.new(Elastic::NestedType, &_block)
        using.target = (target || _name.to_s.singularize.camelize.constantize) rescue nil
      end

      using = (_name + '_index').camelize.constantize if using.nil?

      definition.register_field Elastic::Fields::Nested.new(_name, using)
    end
  end
end
