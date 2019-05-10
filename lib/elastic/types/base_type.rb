module Elastic::Types
  class BaseType < Elastic::Core::Serializer
    def self.target=(_name_or_class)
      pre_definition.target = _name_or_class
    end

    def self.pre_definition
      @pre_definition ||= Elastic::Core::Definition.new.tap do |definition|
        definition.target = default_target unless default_target.nil?
      end
    end

    def self.definition
      @definition ||= begin
        pre_definition.fields.each do |field|
          field.disable_mapping_inference if original_value_occluded? field.name
        end

        pre_definition.freeze
        pre_definition
      end
    end

    def self.freeze_definition
      definition # calling definition freezes it
    end

    def initialize(_object)
      super(self.class.definition, _object)
    end

    def self.default_target
      @default_target ||= begin
        target = to_s.match(/^(.*)Index$/)
        target ? target[1] : nil
      end
    end

    private_class_method :default_target
  end
end
