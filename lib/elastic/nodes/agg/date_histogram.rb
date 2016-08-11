module Elastic::Nodes::Agg
  class DateHistogram < Elastic::Nodes::BaseAgg
    include Elastic::Nodes::Concerns::Aggregable
    include Elastic::Nodes::Concerns::Bucketed

    def self.build(_name, _field, interval: nil)
      super(_name).tap do |node|
        node.field = _field
        node.interval = interval
      end
    end

    attr_accessor :field
    attr_reader :interval

    def interval=(_value)
      raise ArgumentError, 'invalid interval' if _value && !valid_interval?(_value)
      @interval = _value
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

      render_aggs({ 'date_histogram' => hash }, _options)
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.interval = @interval
      _clone
    end

    def valid_interval?(_value)
      /^\d+(\.\d+)?(y|M|w|d|h|m|s)$/ === _value
    end
  end
end
