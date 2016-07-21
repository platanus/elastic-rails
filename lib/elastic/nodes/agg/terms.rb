module Elastic::Nodes::Agg
  class Terms < Elastic::Nodes::Base
    include Elastic::Nodes::Aggregable
    include Elastic::Nodes::Bucketed

    clone_and_simplify_with do |clone|
      clone.field = @field
      clone.size = @size
    end

    def self.build(_field, size: nil)
      new.tap do |node|
        node.field = _field
        node.size = size
      end
    end

    attr_accessor :field, :size

    def render
      options = { 'field' => @field.to_s }
      options['size'] = @size if @size

      render_aggs 'terms' => options
    end
  end
end
