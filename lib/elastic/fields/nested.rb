module Elastic::Fields
  class Nested
    attr_reader :name, :index

    def initialize(_name, _index)
      @name = _name.to_s
      @index = _index
    end

    def expanded_names
      [@name] + @index.definition.expanded_field_names.map { |n| @name + '.' + n }
    end

    def validate
      nil
    end

    def needs_inference?
      false
    end

    def disable_mapping_inference
    end

    def freeze
      @index.freeze_definition
      super
    end

    def mapping_options
      @index.definition.as_es_mapping.merge!(type: :nested)
    end

    def get_field(_name)
      @index.definition.get_field _name
    end

    def prepare_value_for_query(_value)
      _value
    end

    def prepare_value_for_index(_values)
      _values.map { |v| @index.new(v).as_es_document(only_data: true) }
    end
  end
end
