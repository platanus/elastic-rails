module Elastic::Nodes::Agg
  class DateHistogram < Elastic::Nodes::Base
    include Elastic::Nodes::Aggregable

    clone_and_simplify_with do |clone|
      clone.field = @field
      clone.interval = @size
    end

    attr_accessor :field
    attr_reader :interval

    def interval=(_value)
      raise ArgumentError, 'invalid interval' if _value && !valid_interval?(_value)
      @interval = _value
    end

    def render
      options = { 'field' => @field.to_s }
      options['interval'] = @interval if @interval

      render_aggs 'date_histogram' => options
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
