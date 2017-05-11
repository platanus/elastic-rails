module Elastic::Dsl
  module MetricBuilder
    def average(_field, _options = {})
      aggregate_metric(Elastic::Nodes::Agg::Average, _field, _options, 'avg_%s')
    end

    def sum(_field, _options = {})
      aggregate_metric(Elastic::Nodes::Agg::Sum, _field, _options, 'sum_%s')
    end

    def minimum(_field, _options = {})
      aggregate_metric(Elastic::Nodes::Agg::Minimum, _field, _options, 'min_%s')
    end

    def maximum(_field, _options = {})
      aggregate_metric(Elastic::Nodes::Agg::Maximum, _field, _options, 'max_%s')
    end

    def stats(_field, _options = {})
      aggregate_metric(Elastic::Nodes::Agg::Stats, _field, _options, '%s_stats')
    end

    private

    def aggregate_metric(_klass, _field, _options, _default_name, &_block)
      # TODO: detect nested name and wrap node
      name = _options.delete(:as) || sprintf(_default_name, _field)
      node = _klass.build(name, _field, _options)
      _block.call node unless _block.nil?
      aggregate node
    end
  end
end
