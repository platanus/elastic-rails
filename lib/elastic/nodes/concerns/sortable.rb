module Elastic::Nodes::Concerns
  module Sortable
    ORDER = [:asc, :desc]
    MODES = [:min, :max, :sum, :avg, :median]

    def clone
      copy_sorts super
    end

    def simplify
      copy_sorts super
    end

    def sorts
      registered_sorts.dup
    end

    def add_sort(_field, order: :asc, mode: nil, missing: nil)
      raise ArgumentError, "invalid sort order #{order}" unless ORDER.include?(order.to_sym)
      raise ArgumentError, "invalid sort mode #{mode}" if mode && !MODES.include?(mode.to_sym)

      options = { 'order' => order.to_s }
      options['mode'] = mode.to_s if mode.present?
      options['missing'] = missing if missing.present?

      registered_sorts << { _field.to_s => options.freeze }.freeze
      self
    end

    def reset_sorts
      @registered_sorts = nil
      self
    end

    protected

    attr_writer :registered_sorts

    private

    def copy_sorts(_clone)
      _clone.registered_sorts = sorts
      _clone
    end

    def render_sorts
      sorts
    end

    def registered_sorts
      @registered_sorts ||= []
    end
  end
end
