module Elastic::Nodes
  class Match < BaseWithBoost
    MATCH_MODES = [:boolean, :phrase, :phrase_prefix]

    attr_accessor :field, :query
    attr_reader :mode

    def query=(_query)
      raise ArgumentError, 'query must be a string' unless _query.is_a? String
      @query = _query
    end

    def mode=(_value)
      _value = _value.try(:to_sym)
      raise ArgumentError, 'invalid match mode' if !_value.nil? && !MATCH_MODES.include?(_value)
      @mode = _value
    end

    def clone
      base_clone.tap do |clone|
        clone.field = @field
        clone.query = @query
        clone.mode = @mode
      end
    end

    def render
      query_options = { 'query' => @query }
      query_options['type'] = @mode.to_s unless @mode.nil? || @mode == :boolean

      { "match" => { @field.to_s => render_boost(query_options) } }
    end

    def simplify
      return self
    end
  end
end
