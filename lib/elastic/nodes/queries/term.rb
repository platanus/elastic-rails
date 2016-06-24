module Elastic::Nodes
  class Term < Base
    attr_reader :field, :terms

    def initialize(_field, _terms)
      _terms = Array(_terms)
      raise ArgumentError, 'must provide at least one term' if _terms.length == 0

      @field = _field
      @terms = Array(_terms)
    end

    def clone
      self.class.new @field, @terms
    end

    def render
      if @terms.length == 1
        { "term" => { @field.to_s => @terms.first } }
      else
        { "terms" => { @field.to_s => @terms } }
      end
    end

    def simplify
      return self
    end
  end
end
