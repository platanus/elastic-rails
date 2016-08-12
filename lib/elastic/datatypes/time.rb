module Elastic::Datatypes
  class Time < Default
    def mapping_options
      options = super
      options[:type] = 'date'
      options
    end

    def prepare_value_for_result(_value)
      # TODO: set timezone
      case _value
      when ::String
        ::Time.parse(_value)
      when ::Integer
        ::Time.at(_value / 1000)
      else
        _value
      end
    end

    def supported_aggregations
      [:date_histogram] + super
    end

    def date_histogram_aggregation_defaults
      { interval: '1h' }
    end
  end
end
