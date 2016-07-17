module Elastic::Nodes::Agg
  class DateHistogram < Elastic::Nodes::Base
    attr_accessor :field
    attr_reader :interval

    def interval=(_value)
      raise ArgumentError, 'invalid interval' if _value && !valid_interval?(_value)
      @interval = _value
    end

    def clone
      base_clone.tap do |clone|
        clone.field = @field
        clone.interval = @interval
      end
    end

    def render
      options = { 'field' => @field.to_s }
      options['interval'] = @interval if @interval

      { 'date_histogram' => options }
    end

    def simplify
      clone
    end

    private

    def valid_interval?(_value)
      /^\d+(\.\d+)?(y|M|w|d|h|m|s)$/ === _value
    end
  end
end
