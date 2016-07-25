module Elastic::Results
  class HitCollection < Base
    include Enumerable

    def initialize(_hits)
      @hits = _hits
    end

    def count
      @hits.count
    end

    def [](_idx)
      @hits[_idx].try(:ref)
    end

    def last
      @hits.last.try(:ref)
    end

    def each(&_block)
      @hits.map(&:ref).each(&_block)
    end

    def each_hit(&_block)
      @hits.each(&_block)
    end

    def each_with_score(&_block)
      @hits.map { |h| [h.ref, h.score] }.each(&_block)
    end

    def traverse(&_block)
      super
      @hits.each { |h| h.traverse(&_block) }
    end
  end
end
