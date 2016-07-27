module Elastic::Nodes::Agg
  class Maximum < BaseMetric
    private def metric
      'max'
    end
  end
end
