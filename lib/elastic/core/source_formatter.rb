module Elastic::Core
  class SourceFormatter
    def initialize(_definition)
      @definition = _definition
    end

    def format_field(_field, _value)
      field = @definition.get_field _field
      return _value if field.nil?
      field.prepare_value_for_result _value
    end

    def format(_source)
      _source.each do |key, value|
        field = @definition.get_field key
        next if field.nil?
        _source[key] = field.prepare_value_for_result(value)
      end
    end
  end
end
