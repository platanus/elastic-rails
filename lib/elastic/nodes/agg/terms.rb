module Elastic::Nodes::Agg
  class Terms < Elastic::Nodes::Base
    attr_accessor :field, :size

    def clone
      base_clone.tap do |clone|
        clone.field = @field
        clone.size = @size
      end
    end

    def render
      options = { 'field' => @field.to_s }
      options['size'] = @size if @size

      { 'terms' => options }
    end

    def simplify
      clone
    end
  end
end
