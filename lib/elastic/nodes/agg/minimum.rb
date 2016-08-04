module Elastic::Nodes::Agg
  class Minimum < BaseMetric
    private

    def metric
      'min'
    end
  end
end
