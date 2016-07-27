module Elastic::Commands
  class BuildAggFromParams < Elastic::Support::Command.new(:index, :params)
    def perform
      parse_params
      raise ArgumentError, "field not mapped: #{@field}" unless index.definition.has_field? @field

      path = parse_nesting_path
      raise NotImplementedError, "nested paths not yet supported in aggregations" if path

      build_node
    end

    private

    def agg_name
      @options.fetch(:as, @field)
    end

    def parse_params
      @field = params[0].to_s
      @options = params[1] || {}
    end

    def parse_nesting_path
      dot_index = @field.rindex('.')
      return nil if dot_index.nil?
      @field.slice(0, dot_index)
    end

    def build_node
      type = @options[:type]
      type = infer_type_from_options_and_mapping if type.nil?

      send("build_#{type}")
    end

    def infer_type_from_options_and_mapping
      return :range if @options.key? :ranges

      properties = index.mapping.get_field_options @field
      return :date_histogram if properties['type'] == 'date'
      return :histogram if @options.key? :interval

      :terms
    end

    def build_range
      raise NotImplementedError, 'range aggregation not yet implemented'
    end

    def build_histogram
      raise NotImplementedError, 'histogram aggregation not yet implemented'
    end

    def build_date_histogram
      Elastic::Nodes::Agg::DateHistogram.build(agg_name, @field, interval: @options[:interval])
    end

    def build_terms
      Elastic::Nodes::Agg::Terms.build(agg_name, @field, size: @options[:size])
    end
  end
end
