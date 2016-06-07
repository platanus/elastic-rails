module Elastic
  class Histogram
    include Capabilities::ContextHandler
    include Capabilities::AggregationBuilder

    attr_accessor :resolution

    def initialize(_time_field, _resolution)
      @time_field = _time_field
      @resolution = _resolution
    end

    def open_for(_field)
      with_context(:aggregate, :open_for) do |name|
        register_aggregation(name, {
          top_hits: {
            sort: [{ @time_field => { order: "asc" } }],
            _source: { include: [ _field ]  },
            size: 1
          }
        })
      end
    end

    def close_for(_field)
      with_context(:aggregate, :close_for) do |name|
        register_aggregation(name, {
          top_hits: {
            sort: [{ @time_field => { order: "desc" } }],
            _source: { include: [ _field ]  },
            size: 1
          }
        })
      end
    end

    def render
      json = {
        date_histogram: {
          field: @time_field,
          interval: @resolution,
        }
      }

      render_aggregations_to json
      json
    end
  end
end
