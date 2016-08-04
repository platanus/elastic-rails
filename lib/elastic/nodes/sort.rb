module Elastic::Nodes
  class Sort < Base
    ORDER = [:asc, :desc]
    MODES = [:min, :max, :sum, :avg, :median]

    attr_accessor :child

    def initialize
      @sorts = []
    end

    def sorts
      @sorts.dup
    end

    def add_sort(_field, order: :asc, mode: nil, missing: nil)
      raise ArgumentError, "invalid sort order #{order}" unless ORDER.include?(order.to_sym)
      raise ArgumentError, "invalid sort mode #{mode}" if mode && !MODES.include?(mode.to_sym)

      options = { 'order' => order.to_s }
      options['mode'] = mode.to_s if mode.present?
      options['missing'] = missing if missing.present?

      @sorts << { _field => options.freeze }.freeze
      self
    end

    def add_score_sort(order: :desc)
      raise ArgumentError, "invalid sort order #{order}" unless ORDER.include?(order.to_sym)

      add_sort('_score', order: order)
    end

    def reset_sorts
      @sorts = []
      self
    end

    def clone
      prepare_clone(super, child.try(:clone))
    end

    def simplify
      if @sorts.empty?
        child.try(:simplify)
      else
        prepare_clone(super, child.try(:simplify))
      end
    end

    def render
      hash = child.render
      hash['sort'] = render_sorts
      hash
    end

    def handle_result(_raw)
      @child.handle_result _raw
    end

    def traverse(&_block)
      super
      @child.traverse(&_block)
    end

    protected

    attr_writer :sorts

    private

    def prepare_clone(_clone, _child)
      _clone.child = _child
      _clone.sorts = @sorts.dup
      _clone
    end

    def render_sorts
      @sorts.dup
    end
  end
end
