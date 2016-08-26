module Elastic::Fields
  class Nested
    attr_reader :name, :index

    def initialize(_name, _index)
      @name = _name.to_s
      @index = _index
    end

    def merge!(_options)
      # does nothing
    end

    def validate
      nil
    end

    def needs_inference?
      false
    end

    def nested?
      true
    end

    def disable_mapping_inference
      # does nothing, inference is always disabled
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

    def prepare_value_for_index(_values)
      _values.map { |v| @index.new(v).as_es_document(only_data: true) }
    end

    def prepare_value_for_result(_values)
      formatter = Elastic::Core::SourceFormatter.new @index.definition
      _values.each { |v| formatter.format(v) }
    end

    def select_aggregation(_from)
      nil
    end
  end
end
