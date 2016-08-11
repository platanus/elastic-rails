module Elastic::Nodes
  class Term < Base
    include Concerns::Boostable
    include Concerns::FieldQuery

    BOOLEAN_MODE = [:any, :all]

    attr_accessor :field, :mode

    def terms=(_terms)
      @terms = _terms.dup.to_a
    end

    def mode=(_value)
      if !_value.nil? && !BOOLEAN_MODE.include?(_value)
        raise ArgumentError, "invalid mode #{_value}"
      end

      @mode = _value
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

    def render(_options = {})
      raise ArgumentError, "terms not provided for #{@field}" if !@terms

      if @terms.length == 1
        { 'term' => { render_field(_options) => render_boost('value' => @terms.first) } }
      elsif @mode == :all && !@terms.empty?
        {
          'bool' => render_boost(
            'must' => @terms.map { |t| { 'term' => { render_field(_options) => t } } }
          )
        }
      else
        { 'terms' => render_boost(render_field(_options) => @terms) }
      end
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.terms = @terms
      _clone.mode = @mode
      _clone
    end
  end
end
