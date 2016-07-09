module Elastic::Nodes
  class FunctionScore < BaseWithBoost
    SCORE_MODES = [:multiply, :sum, :avg, :first, :max, :min]
    BOOST_MODES = [:multiply, :replace, :sum, :avg, :max, :min]

    def self.build(_query)
      new.tap { |node| node.query = _query }
    end

    attr_accessor :query
    attr_reader :score_mode, :boost_mode

    def initialize
      @functions = []
    end

    def functions=(_values)
      @functions = _values.dup.to_a
    end

    def score_mode=(_value)
      raise ArgumentError, "invalid score mode #{_value}" unless SCORE_MODES.include? _value
      @score_mode = _value
    end

    def boost_mode=(_value)
      raise ArgumentError, "invalid boost mode #{_value}" unless BOOST_MODES.include? _value
      @boost_mode = _value
    end

    def add_weight_function(_weight, filter: nil)
      add_function(nil, nil, filter, _weight)
    end

    def add_field_function(_field, factor: 1, modifier: :none, missing: 1, weight: nil, filter: nil)
      add_function('field_value_factor', {
        'field' => _field,
        'factor' => factor,
        'modifier' => modifier,
        'missing' => missing
      }, filter, weight)
    end

    def add_decay_function(_field, _options = {})
      raise NotImplementedError, 'decay function not implemented'
    end

    def clone
      clone_with_query @query.clone
    end

    def clone_with_query(_query)
      base_clone.tap do |clone|
        clone.query = _query
        clone.functions = @functions
        clone.boost_mode = @boost_mode
        clone.score_mode = @score_mode
      end
    end

    def render
      function_score = { 'query' => @query.render }
      function_score['boost_mode'] = @boost_mode.to_s if @boost_mode && @boost_mode != :multiply

      if @functions.length > 1
        function_score['score_mode'] = @score_mode.to_s if @score_mode && @score_mode != :multiply
        function_score['functions'] = @functions
      else
        function_score.merge! @functions.first
      end

      { 'function_score' => render_boost(function_score) }
    end

    def simplify
      new_query = query.simplify

      if @functions.length == 0
        return new_query if boost.nil?

        if new_query.is_a?(BaseWithBoost) && new_query.boost.nil?
          # some queries support the boost attribute directly
          new_query.boost = boost
          return new_query
        end
      end

      clone_with_query new_query
    end

    private

    def add_function(_function, _params, _filter, _weight)
      @functions << {}.tap do |hash|
        hash[_function] = _params if _function
        hash['weight'] = _weight unless _weight.nil?
        hash['filter'] = _filter.render unless _filter.nil?
      end
      self
    end
  end
end
