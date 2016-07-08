module Elastic::Nodes
  class Term < BaseWithBoost
    attr_accessor :field

    def terms=(_terms)
      @terms = _terms.dup.to_a
    end

    def terms
      @terms.each
    end

    def clone
      base_clone.tap do |clone|
        clone.field = @field
        clone.terms = @terms
      end
    end

    def render
      raise ArgumentError, 'must provide at least one term' if !@terms || @terms.length == 0

      if @terms.length == 1
        { "term" => { @field.to_s => render_boost('value' => @terms.first) } }
      else
        { "terms" => render_boost(@field.to_s => @terms) }
      end
    end

    def simplify
      return self
    end
  end
end
