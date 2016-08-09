module Elastic::Commands
  class BuildAggFromParams < Elastic::Support::Command.new(:index, :params)
    def perform
      parse_params
      raise ArgumentError, "field not mapped: #{@field}" if field_definition.nil?

      path = parse_nesting_path
      raise NotImplementedError, "nested paths not yet supported in aggregations" if path

      build_node
    end

    private

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
      type_options = @options.key?(:type) ? [@options[:type]] : infer_type_options

      default_options = field_definition.select_aggregation type_options
      if default_options.nil?
        raise "aggregations not supported by #{@field}" if type_options.empty?
        raise "#{type_options.first} aggregation not supported by #{@field}"
      end

      node_options = default_options.merge! @options
      send("build_#{node_options[:type]}", node_options)
    end

    def infer_type_options
      return [:range] if @options.key? :ranges
      return [:histogram, :date_histogram] if @options.key? :interval
      nil
    end

    def field_definition
      @field_definition ||= index.definition.get_field @field
    end

    def build_range(_options)
      raise NotImplementedError, 'range aggregation not yet implemented'
    end

    def build_histogram(_options)
      raise NotImplementedError, 'histogram aggregation not yet implemented'
    end

    def build_date_histogram(_options)
      Elastic::Nodes::Agg::DateHistogram.build(agg_name, @field, interval: _options[:interval])
    end

    def build_terms(_options)
      Elastic::Nodes::Agg::Terms.build(agg_name, @field, size: _options[:size])
    end

    def agg_name
      @options.fetch(:as, @field)
    end
  end
end
