module Elastic::Nodes
  class Match < Base
    MATCH_MODES = [:boolean, :phrase, :phrase_prefix]

    attr_reader :field, :value, :mode

    def initialize(_field, _value, mode: :boolean)
      @field = _field
      self.value = _value
      self.mode = mode
    end

    def value=(_value)
      raise ArgumentError, 'query value must be a string' unless _value.is_a? String
      @value = _value
    end

    def mode=(_value)
      raise ArgumentError, 'invalid match mode' unless MATCH_MODES.include? _value.to_sym
      @mode = _value
    end

    def clone
      self.class.new(@field, @value, mode: @mode)
    end

    def render
      query_options = { 'query' => @value }
      query_options['type'] = @mode.to_s unless @mode.nil?

      { "match" => { @field.to_s => query_options } }
    end

    def simplify
      return self
    end
  end
end
