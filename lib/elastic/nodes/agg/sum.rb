module Elastic::Nodes::Agg
  class Sum < BaseMetric
    private

    def metric
      'sum'
    end
  end
end
