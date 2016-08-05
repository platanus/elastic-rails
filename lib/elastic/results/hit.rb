module Elastic::Results
  class Hit < Base
    attr_reader :type, :id, :score, :source
    attr_accessor :data

    def initialize(_type, _id, _score, _source)
      @type = _type
      @id = _id
      @score = _score
      @source = _source
    end
  end
end
