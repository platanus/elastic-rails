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

    def read_elastic_type
      object.class.to_s
    end

    def read_elastic_id
      if has_attribute_for_indexing?(:id)
        read_attribute_for_indexing(:id)
      end
    end

    def as_elastic_document(only_data: false)
      data = {}.tap do |hash|
        fields.each do |field|
          value = read_attribute_for_indexing(field.name)
          value = field.prepare_value_for_index(value)
          hash[field.name] = value
        end
      end

      return data if only_data

      result = {
        '_type' => read_elastic_type,
        'data' => data
      }

      read_elastic_id.tap { |id| result['_id'] = id unless id.nil? }
      result
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
