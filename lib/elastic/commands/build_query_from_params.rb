module Elastic::Commands
  class BuildQueryFromParams < Elastic::Support::Command.new(:index, :params, block: nil)
    def perform
      if block
        # TODO: builder mode, support nesting through first parameter
      else
        node = build_or_node(params)
      end

      node.try(:simplify)
    end

    private

    def build_or_node(_array)
      parts = _array.map do |part|
        case part
        when Hash
          build_and_node part
        when Elastic::Query
          extract_query_node part
        else
          raise ArgumentError, "expected hash or query but got #{part.class}"
        end
      end.reject(&:nil?)

      return nil if parts.empty?
      Elastic::Nodes::Boolean.build_or(parts)
    end

    def build_and_node(_hash)
      parts = _hash.map do |field, options|
        build_query_node field, options
      end.reject(&:nil?)

      return nil if parts.empty?
      Elastic::Nodes::Boolean.build_and(parts)
    end

    def extract_query_node(_query)
      raise ArgumentError, "query type mismatch, expected #{index.class}" if _query.index != index
      _query.as_query_node
    end

    def build_query_node(_field, _options)
      path, field = split_nesting_path(_field.to_s)
      if path
        definition = resolve_field_defintion! path
        raise ArgumentError, "invalid nesting path #{path}" unless definition.nested?
        build_nested_query(path, definition, field => _options)
      else
        build_regular_query(field, _options)
      end
    end

    def split_nesting_path(_field)
      dot_index = _field.rindex('.')
      return [nil, _field] if dot_index.nil?
      [_field[0..dot_index - 1], _field[dot_index + 1..-1]]
    end

    def build_regular_query(_field, _options)
      definition = resolve_field_defintion!(_field)

      if definition.nested?
        build_nested_query(_field, definition, _options)
      else
        query_type = infer_query_type definition, _options
        raise "query not supported by #{_field}" if query_type.nil?
        _options = option_to_hash(query_type, _options) unless _options.is_a? Hash
        _options = definition.public_send("#{query_type}_query_defaults").merge(_options)

        send("build_#{query_type}", definition, _options)
      end
    end

    def resolve_field_defintion!(_path)
      definition = index.definition.get_field _path
      raise ArgumentError, "field not mapped: #{_path}" if definition.nil?
      definition
    end

    def infer_query_type(_definition, _options)
      alternatives = infer_query_type_from_options(_options)
      if alternatives.nil?
        _definition.supported_queries.first
      else
        _definition.supported_queries.find { |q| alternatives.include? q }
      end
    end

    def build_nested_query(_path, _definition, _query)
      case _query
      when Elastic::NestedQuery
        if _query.index != _definition.index
          raise ArgumentError,
            "query type mismatch for #{_path}, expected #{_definition.index.class}"
        end

        return _query.as_node.tap { |node| node.path = _path }
      when Hash
        _query = [_query]
      end

      nested_node = BuildQueryFromParams.for(index: _definition.index, params: _query)
      Elastic::Nodes::Nested.build _path, nested_node
    end

    def infer_query_type_from_options(_options)
      case _options
      when Hash
        return [_options[:type].to_sym] if _options.key?(:type)
        return [:term] if _options.key?(:term) || _options.key?(:terms)
        return [:match] if _options.key? :matches
        return [:range] if _options.key?(:gte) || _options.key?(:gt)
        return [:range] if _options.key?(:lte) || _options.key?(:lt)
      when String, Symbol
        return [:term, :match]
      when Array
        return [:term]
      when Range
        return [:range]
      end

      nil
    end

    def option_to_hash(_query_type, _value)
      case _query_type
      when :term
        { terms: _value }
      when :match
        { matches: _value.to_s }
      when :range
        { gte: _value.begin, (_value.exclude_end? ? :lt : :lte) => _value.end }
      end
    end

    # NOTE: the following methods could be placed in separate factories.

    def build_term(_field, _options)
      terms = Array(_options.fetch(:term, _options[:terms]))

      Elastic::Nodes::Term.new.tap do |node|
        node.field = _field.name
        node.mode = _options[:mode]
        node.terms = terms.map { |t| _field.prepare_value_for_query(t) }
      end
    end

    def build_range(_field, _options)
      Elastic::Nodes::Range.new.tap do |node|
        node.field = _field.name
        node.gte = _field.prepare_value_for_query(_options[:gte]) if _options.key? :gte
        node.gt = _field.prepare_value_for_query(_options[:gt]) if _options.key? :gt
        node.lte = _field.prepare_value_for_query(_options[:lte]) if _options.key? :lte
        node.lt = _field.prepare_value_for_query(_options[:lt]) if _options.key? :lt
      end
    end

    def build_match(_field, _options)
      Elastic::Nodes::Match.new.tap do |node|
        node.field = _field.name
        node.query = _field.prepare_value_for_query(_options[:matches])
      end
    end
  end
end
