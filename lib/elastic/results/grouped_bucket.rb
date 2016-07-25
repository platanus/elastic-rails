module Elastic::Results
  class GroupedBucket < Base
    extend Forwardable
    include Enumerable

    def_delegators :@bucket, :[], :each

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
