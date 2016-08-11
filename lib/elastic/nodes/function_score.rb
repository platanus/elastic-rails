module Elastic::Nodes
  class FunctionScore < Base
    include Concerns::Boostable

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
      raise ArgumentError, "invalid score mode #{_value}" if _value && !SCORE_MODES.include?(_value)
      @score_mode = _value
    end

    def boost_mode=(_value)
      raise ArgumentError, "invalid boost mode #{_value}" if _value && !BOOST_MODES.include?(_value)
      @boost_mode = _value
    end

    def add_weight_function(_weight, filter: nil)
      add_function(nil, nil, filter, _weight)
    end

    def add_field_function(_field, factor: 1, modifier: :none, missing: 1, weight: nil, filter: nil)
      params = {
        'field' => _field,
        'factor' => factor,
        'modifier' => modifier,
        'missing' => missing
      }

      add_function('field_value_factor', params, filter, weight)
    end

    def add_decay_function(_field, _options = {})
      raise NotImplementedError, 'decay function not implemented'
    end

    def traverse(&_block)
      super
      @query.traverse(&_block)
    end

    def render(_options = {})
      hash = { 'query' => @query.render(_options) }
      hash['boost_mode'] = @boost_mode.to_s if @boost_mode && @boost_mode != :multiply

      # TODO: add support for the query_path option
      if @functions.length > 1
        hash['score_mode'] = @score_mode.to_s if @score_mode && @score_mode != :multiply
        hash['functions'] = @functions
      elsif @functions.length == 1
        hash.merge! @functions.first
      end

      { 'function_score' => render_boost(hash) }
    end

    alias :super_clone :clone
    private :super_clone

    def clone
      prepare_clone super, @query.clone
    end

    def clone_with_query(_query)
      prepare_clone super_clone, _query
    end

    def simplify
      new_query = query.simplify

      if @functions.empty?
        return new_query if boost.nil?

        if new_query.class.include?(Concerns::Boostable) && new_query.boost.nil?
          new_query.boost = boost
          return new_query
        end
      end

      prepare_clone(super, new_query)
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

    def prepare_clone(_clone, _query)
      _clone.query = _query
      _clone.functions = @functions
      _clone.boost_mode = @boost_mode
      _clone.score_mode = @score_mode
      _clone
    end
  end
end
