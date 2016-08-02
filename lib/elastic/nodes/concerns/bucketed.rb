module Elastic::Nodes::Concerns
  module Bucketed
    def handle_result(_raw)
      buckets = _raw['buckets'].map do |raw_bucket|
        aggs = load_aggs_results(raw_bucket)

        # TODO: allow bucket aggregation to return single nested aggregation if node is
        # configured that way
        # return Elastic::Results::SimpleBucket.new(raw_bucket['key'], aggs.first) if blebliblu

        Elastic::Results::Bucket.new(raw_bucket['key'], raw_bucket['doc_count'], aggs)
      end

      Elastic::Results::BucketCollection.new buckets
    end
  end
end
