module Elastic::Results
  class ScoredCollection < Base
    include Enumerable

    def initialize(_collection)
      @collection = _collection
    end

    def count
      @collection.count
    end

    def [](_idx)
      @collection[_idx].try(:data)
    end

    def last
      @collection.last.try(:data)
    end

    def each(&_block)
      @collection.map(&:data).each(&_block)
    end

    def each_with_score(&_block)
      @collection.map { |sd| [sd.data, sd.score] }.each(&_block)
    end

    def map_with_score(&_block)
      ScoredCollection.new(
        @collection.map { |sd| ScoredItem.new(_block.call(sd), sd.score) }.to_a
      )
    end

    def traverse(&_block)
      super
      @collection.each { |sd| sd.traverse(&_block) }
    end

    private

    attr_reader :collection
  end
end
