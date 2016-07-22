module Elastic::Nodes::Agg
  class Terms < Elastic::Nodes::Base
    include Elastic::Nodes::Aggregable
    include Elastic::Nodes::Bucketed

    def self.build(_field, size: nil)
      new.tap do |node|
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

    def render
      options = { 'field' => @field.to_s }
      options['size'] = @size if @size

      render_aggs 'terms' => options
    end

    private

    def prepare_clone(_clone)
      _clone.field = @field
      _clone.size = @size
      _clone
    end
  end
end
