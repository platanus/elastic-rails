module Elastic::Nodes::Concerns
  module FieldQuery
    attr_accessor :field

    def render_field(_options)
      return "#{_options[:query_path]}.#{@field}" if _options.key? :query_path
      @field.to_s
    end
  end
end
