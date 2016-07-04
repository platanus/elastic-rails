module Elastic::Core
  class Serializer
    attr_reader :object

    def self.original_value_occluded?(_field)
      public_method_defined? _field
    end

    def initialize(_definition, _object)
      # TODO: validate that object is of type <target>?
      @definition = _definition
      @object = _object
    end

    def fields
      @definition.fields
    end

    def as_es_document
      {}.tap do |hash|
        fields.each do |field|
          value = read_value_for_indexing(field.name)
          value = field.prepare_value_for_index(value)
          hash[field.name] = value
        end
      end
    end

    private

    def read_value_for_indexing(_field)
      respond_to?(_field) ? public_send(_field) : @object.public_send(_field)
    end
  end
end