module Elastic::Nodes
  class Sort < Base
    include Concerns::Sortable

    attr_accessor :child

    def add_score_sort(order: :desc)
      add_sort('_score', order: order)
    end

    def clone
      prepare_clone(super, child.try(:clone))
    end

    def simplify
      if registered_sorts.empty?
        child.try(:simplify)
      else
        prepare_clone(super, child.try(:simplify))
      end
    end

    def render(_options = {})
      hash = child.render(_options)
      hash['sort'] = render_sorts
      hash
    end

    def handle_result(_raw, _formatter)
      @child.handle_result(_raw, _formatter)
    end

    def traverse(&_block)
      super
      @child.traverse(&_block)
    end

    private

    def prepare_clone(_clone, _child)
      _clone.child = _child
      _clone
    end
  end
end
