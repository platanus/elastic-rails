module Elastic::Results
  class HitCollection < ScoredCollection
    def each_hit(&_block)
      collection.each(&_block)
    end
  end
end
