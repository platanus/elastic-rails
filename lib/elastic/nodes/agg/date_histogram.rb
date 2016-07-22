module Elastic::Nodes::Agg
  class DateHistogram < Elastic::Nodes::Base
    include Elastic::Nodes::Aggregable
    include Elastic::Nodes::Bucketed

    def self.build(_field, interval: nil)
      new.tap do |node|
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

    def render
      options = { 'field' => @field.to_s }
      options['interval'] = @interval if @interval

      render_aggs 'date_histogram' => options
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
