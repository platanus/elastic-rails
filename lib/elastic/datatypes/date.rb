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

    def prepare_for_result(_value)
      case _value
      when String
        ::Time.parse(_value).utc.to_date
      when Integer
        ::Time.at(_value / 1000).utc.to_date
      else
        _value
      end
    end

    def supported_aggregations
      [
        { type: :date_histogram, interval: '1w' }
      ] + super
    end
  end
end
