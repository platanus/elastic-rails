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

    def as_elastic_document(only_meta: false)
      result = { '_type' => object.class.to_s }
      result['_id'] = read_attribute_for_indexing(:id) if has_attribute_for_indexing?(:id)
      result['data'] = as_elastic_source unless only_meta
      result
    end

    def as_elastic_source
      {}.tap do |hash|
        fields.each do |field|
          value = read_attribute_for_indexing(field.name)
          value = field.prepare_value_for_index(value)
          hash[field.name] = value
        end
      end
    end

    private

    def has_attribute_for_indexing?(_name)
      respond_to?(_name) || @object.respond_to?(_name)
    end

    def read_attribute_for_indexing(_name)
      respond_to?(_name) ? public_send(_name) : @object.public_send(_name)
    end
  end
end
