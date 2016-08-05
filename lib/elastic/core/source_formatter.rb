module Elastic::Core
  class SourceFormatter
    def initialize(_mapping)
      @mapping = _mapping
      @treatment_cache = {}
    end

    def format_field(_field, _value)
      treatment = treatment_for _field
      return _value if treatment == :none
      send(treatment, _value)
    end

    def format(_source, _prefix = nil)
      _source.each do |field, value|
        field_name = _prefix ? "#{_prefix}.#{field}" : field

        treatment = treatment_for field_name
        if treatment == :nested
          value.each { |v| format(v, field_name) }
        else
          _source[field] = send(treatment, value) unless treatment == :none
        end
      end
    end

    private

    def treatment_for(_field)
      treatment = @treatment_cache[_field]
      treatment = @treatment_cache[_field] = get_treatment(_field) if treatment.nil?
      treatment
    end

    def get_treatment(_field)
      field_options = @mapping.get_field_options(_field) || {}
      return :nested if field_options['type'] == 'nested'
      return :parse_date if field_options['type'] == 'date'
      :none
    end

    def parse_date(_value)
      # dates come in two flavors, longs or strings:
      return Time.parse(_value) if _value.is_a? String
      Time.at(_value / 1000)
    end
  end
end
