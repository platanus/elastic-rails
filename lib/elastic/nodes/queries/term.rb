module Elastic::Nodes
  class Term < Base
    include Boostable

    clone_and_simplify_with do |clone|
      clone.field = @field
      clone.terms = @terms
    end

    attr_accessor :field

    def terms=(_terms)
      @terms = _terms.dup.to_a
    end

    def terms
      @terms.each
    end

    def render
      raise ArgumentError, 'must provide at least one term' if !@terms || @terms.empty?

      if @terms.length == 1
        { "term" => { @field.to_s => render_boost('value' => @terms.first) } }
      else
        { "terms" => render_boost(@field.to_s => @terms) }
      end
    end
  end
end
