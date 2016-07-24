module Elastic::Results
  class GroupedBucket < Base
    extend Forwardable

    def_delegators :@bucket, :[], :aggs

    def initialize(_keys, _bucket)
      @keys = _keys
      @bucket = _bucket
    end

    def keys(_dim)
      @keys[_dim]
    end

    def traverse(&_block)
      super
      @bucket.traverse(&_block)
    end
  end
end
