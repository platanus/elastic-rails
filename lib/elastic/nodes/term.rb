module Elastic::Nodes
  class Term < Base
    include Concerns::Boostable

    attr_accessor :field

    def terms=(_terms)
      @terms = _terms.dup.to_a
    end

    def terms
      @terms.each
    end

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def render
      raise ArgumentError, 'must provide at least one term' if !@terms || @terms.empty?

      if @terms.length == 1
        { "term" => { @field.to_s => render_boost('value' => @terms.first) } }
      else
        { "terms" => render_boost(@field.to_s => @terms) }
      end
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.terms = @terms
      _clone
    end
  end
end
