module Elastic::Results
  class Hit < Base
    attr_reader :id, :score, :source
    attr_accessor :data

    def initialize(_id, _score, _source)
      @id = _id
      @score = _score
      @source = _source
    end
  end
end
