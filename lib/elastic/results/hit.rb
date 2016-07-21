module Elastic::Results
  class Hit
    attr_accessor :raw, :ref

    def initialize(_raw)
      @raw = _raw
    end

    def id; @raw['_id'] end

    def type; @raw['_type'] end

    def score; @raw['_score'] end

    def source; @raw['_source'] end
  end
end
