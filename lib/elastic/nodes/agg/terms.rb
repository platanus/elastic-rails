module Elastic::Nodes::Agg
  class Terms < Elastic::Nodes::BaseAgg
    include Elastic::Nodes::Concerns::Aggregable
    include Elastic::Nodes::Concerns::Bucketed

    def self.build(_name, _field, size: nil)
      super(_name).tap do |node|
        node.field = _field
        node.size = size
      end
    end

    attr_accessor :field, :size

    def clone
      prepare_clone(super)
    end

    def simplify
      prepare_clone(super)
    end

    def render(_options = {})
      hash = { 'field' => @field.to_s }
      hash['size'] = @size if @size

      render_aggs({ 'terms' => hash }, _options)
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.size = @size
      _clone
    end
  end
end
