module Elastic::Nodes::Concerns
  module Bucketed
    def handle_result(_raw, _formatter)
      buckets = _raw['buckets'].map do |raw_bucket|
        key = _formatter.format_field(field, raw_bucket['key'])
        aggs = load_aggs_results(raw_bucket, _formatter)

        Elastic::Results::Bucket.new(key, raw_bucket['doc_count'], aggs)
      end

      Elastic::Results::BucketCollection.new buckets
    end
  end
end
