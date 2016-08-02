module Elastic::Results
  class ScoredItem < Base
    attr_reader :data, :score

    def initialize(_data, _score)
      @data = _data
      @score = _score
    end
  end
end
