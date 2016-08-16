module Elastic::Nodes
  class Nested < Base
    SCORE_MODES = [:avg, :sum, :min, :max, :none]

    def self.build(_path, _child)
      new.tap do |node|
        node.path = _path
        node.child = _child
      end
    end

    attr_accessor :path, :child
    attr_reader :score_mode

    def traverse(&_block)
      super
      @child.traverse(&_block)
    end

    def clone
      prepare_clone super, @child.clone
    end

    def score_mode=(_value)
      raise ArgumentError, "invalid score mode #{_value}" if _value && !SCORE_MODES.include?(_value)
      @score_mode = _value
    end

    def simplify
      new_child = @child.simplify
      if new_child.is_a? Nested
        prepare_clone(super, new_child.child).tap do |clone|
          clone.path = "#{clone.path}.#{new_child.path}"
        end
      else
        prepare_clone super, new_child
      end
    end

    def render(_options = {})
      path = @path
      path = "#{_options[:query_path]}.#{path}" if _options.key? :query_path

      hash = {
        'path' => path,
        'query' => @child.render(_options.merge(query_path: path))
      }

      hash['score_mode'] = @score_mode.to_s if @score_mode && @score_mode != :avg

      { "nested" => hash }
    end

    private

    def prepare_clone(_clone, _child)
      _clone.path = @path
      _clone.child = _child
      _clone.score_mode = @score_mode
      _clone
    end
  end
end
