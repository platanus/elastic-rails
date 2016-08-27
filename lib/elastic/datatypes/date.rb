module Elastic::Datatypes
  class Date < Default
    def prepare_for_index(_value)
      if !_value.nil? && !_value.is_a?(::Date)
        raise ArgumentError, "expected a date for field #{name}"
      end

      # date is stored as the corresponding utc timestamp in elastic search,
      # no need to convert it here
      _value
    end

    def prepare_value_for_result(_value)
      case _value
      when ::String
        time_zone.parse(_value).to_date
      when ::Integer
        time_zone.at(_value / 1000).to_date
      else
        _value
      end
    end

    def supported_aggregations
      [:date_histogram] + super
    end

    def date_histogram_aggregation_defaults
      { interval: '1w', time_zone: time_zone }
    end

    private

    def time_zone
      @time_zone ||= ActiveSupport::TimeZone.new('UTC') # dates are always UTC
    end
  end
end
