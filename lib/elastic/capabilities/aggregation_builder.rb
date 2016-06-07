module Elastic::Capabilities
  module AggregationBuilder
    def aggregate_in(_name)
      set_context(:aggregate, _name)
    end

    def aggregate
      set_context(:aggregate, nil)
    end

    def sum_of(_field)
      with_context(:aggregate, :sum_of) do |name|
        register_aggregation(name || _field, { "sum" => { "field" => _field } })
      end
    end

    def minimum_for(_field)
      with_context(:aggregate, :minimum_for) do |name|
        register_aggregation(name || _field, { "min" => { "field" => _field } })
      end
    end

    def maximum_for(_field)
      with_context(:aggregate, :maximum_for) do |name|
        register_aggregation(name || _field, { "max" => { "field" => _field } })
      end
    end

    def average_for(_field)
      with_context(:aggregate, :average_for) do |name|
        register_aggregation(name || _field, { "avg" => { "field" => _field } })
      end
    end

    def date_histogram_for(_field, resolution: '1d', &_block)
      with_context(:aggregate, :date_histogram_for) do |name|
        histogram = Elastic::Histogram.new _field, resolution
        _block.call(histogram) if _block
        register_aggregation(name || _field, histogram)
        return histogram unless _block
      end
    end

    private

    def aggregations
      @aggregations ||= []
    end

    def register_aggregation(_name, _definition)
      aggregations << [_name, _definition]
    end

    def render_aggregations_to(_to)
      return if aggregations.length == 0

      _to['aggs'] = aggs = {}

      aggregations.each do |name, definition|
        aggs[name] = definition.respond_to?(:render) ? definition.render : definition
      end
    end
  end
end
