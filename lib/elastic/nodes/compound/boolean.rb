module Elastic::Nodes
  class Boolean < Base
    attr_accessor :minimum_should_match, :disable_coord

    def initialize(must: nil, should: nil, minimum_should_match: nil, disable_coord: nil)
      @must = Array(must || [])
      @should = Array(should || [])
      @minimum_should_match = minimum_should_match
      @disable_coord = disable_coord
    end

    def clone
      self.class.new(
        must: @must,
        should: @should,
        minimum_should_match: @minimum_should_match,
        disable_coord: @disable_coord
      )
    end

    def must(_node)
      @must << _node
    end

    def should(_node)
      @should << _node
    end

    def render
      {}.tap do |boolean|
        boolean['must'] = @must.map(&:render) if @must.length > 0
        boolean['should'] = @should.map(&:render) if @should.length > 0
        boolean['minimum_should_match'] = minimum_should_match unless minimum_should_match.nil?
        boolean['disable_coord'] = disable_coord unless disable_coord.nil?
      end
    end

    def simplify
      new_must = @must.map(&:simplify)
      new_should = @should.map(&:simplify)

      return new_must.first if new_must.length == 1 && new_should.length == 0

      self.class.new(
        must: new_must,
        should: new_should,
        minimum_should_match: @minimum_should_match,
        disable_coord: @disable_coord
      )
    end
  end
end