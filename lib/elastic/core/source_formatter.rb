module Elastic::Core
  class SourceFormatter
    def initialize(_mapping)
      @mapping = _mapping
      @treatment_cache = {}
    end

    def format(_source)
      # TODO: support nested fields
      _source.each do |field, value|
        treatment = treatment_for field
        _source[field] = send(treatment, value) unless treatment == :none
      end
    end

    private

    def treatment_for(_field)
      treatment = @treatment_cache[_field]
      treatment = @treatment_cache[_field] = get_treatment(_field) if treatment.nil?
      treatment
    end

    def get_treatment(_field)
      field_options = @mapping.get_field_options(_field)
      return :join_string if field_options['type'] == 'string'
      :none
    end

    def join_string(_value)
      _value.join ' '
    end
  end
end
