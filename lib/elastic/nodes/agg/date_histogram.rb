module Elastic::Nodes::Agg
  class DateHistogram < Elastic::Nodes::BaseAgg
    include Elastic::Nodes::Concerns::Aggregable
    include Elastic::Nodes::Concerns::Bucketed

    def self.build(_name, _field, interval: nil, time_zone: nil)
      super(_name).tap do |node|
        node.field = _field
        node.interval = interval
        node.time_zone = time_zone
      end
    end

    attr_accessor :field
    attr_reader :interval, :time_zone

    def interval=(_value)
      raise ArgumentError, 'invalid interval' if _value && !valid_interval?(_value)
      @interval = _value
    end

    def time_zone=(_value)
      raise ArgumentError, 'invalid time_zone' if _value && !_value.is_a?(ActiveSupport::TimeZone)
      @time_zone = _value
    end

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def render(_options = {})
      hash = { 'field' => @field.to_s }
      hash['interval'] = @interval if @interval
      hash['time_zone'] = @time_zone.formatted_offset if @time_zone

      render_aggs({ 'date_histogram' => hash }, _options)
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.interval = @interval
      _clone.time_zone = @time_zone
      _clone
    end

    def valid_interval?(_value)
      /^\d+(\.\d+)?(y|M|w|d|h|m|s)$/ === _value
    end
  end
end
