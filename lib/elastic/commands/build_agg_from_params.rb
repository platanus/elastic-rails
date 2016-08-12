module Elastic::Commands
  class BuildAggFromParams < Elastic::Support::Command.new(:index, :params)
    def perform
      parse_params
      raise ArgumentError, "#{@field} not mapped" if field_definition.nil?
      raise ArgumentError, "cant aggregate on #{@field}" if field_definition.nested?

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
      agg_type = infer_agg_type
      raise "aggregation not supported by #{@field}" if agg_type.nil?

      node_options = field_definition.public_send("#{agg_type}_aggregation_defaults")
      node_options = node_options.merge(@options)
      send("build_#{agg_type}", node_options)
    end

    def infer_agg_type
      alternatives = infer_type_options
      if alternatives.nil?
        field_definition.supported_aggregations.first
      else
        field_definition.supported_aggregations.find { |q| alternatives.include? q }
      end
    end

    def infer_type_options
      return [@options[:type].to_sym] if @options.key? :type
      return [:range] if @options.key? :ranges
      return [:histogram, :date_histogram] if @options.key? :interval
      nil
    end

    def apply_query_defaults(_agg_type, _options)
      _definition.default_options_for(query: _query_type).merge(_options)
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
