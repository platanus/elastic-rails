module Elastic::Nodes::Agg
  class Average < BaseMetric
    private

    def metric
      'avg'
    end
  end
end
