module Elastic::Types
  class BaseType < Elastic::Core::Serializer
    def self.target=(_name_or_class)
      pre_definition.targets = [_name_or_class]
    end

    def self.targets=(_names_or_classes)
      pre_definition.targets = _names_or_classes
    end

    def self.pre_definition
      @pre_definition ||= Elastic::Core::Definition.new.tap do |definition|
        definition.targets = [default_target] unless default_target.nil?
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
