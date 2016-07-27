module Elastic::Results
  class BucketCollection < Base
    extend Forwardable
    include Enumerable

    def_delegators :@buckets, :last, :first, :count, :[], :each

    def initialize(_buckets)
      @buckets = _buckets
    end

    def traverse(&_block)
      super
      @buckets.each { |b| b.traverse(&_block) }
    end
  end
end
