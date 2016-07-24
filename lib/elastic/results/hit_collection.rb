module Elastic::Results
  class HitCollection < Base
    extend Forwardable
    include Enumerable

    def_delegators :@hits, :last, :first, :count, :[], :each

    def initialize(_hits)
      @hits = _hits
    end

    def traverse(&_block)
      super
      @hits.each { |h| h.traverse(&_block) }
    end
  end
end
