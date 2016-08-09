module Elastic::Commands
  class BuildQueryFromParams < Elastic::Support::Command.new(
    :index, :params, block: nil, prefix: nil
  )

    def perform
      if block
        # TODO: builder mode, support nesting through first parameter
      else
        node = Elastic::Nodes::Boolean.build_or(params.map do |part|
          Elastic::Nodes::Boolean.build_and(part.map do |field, options|
            field = field.to_s
            path = get_nesting_path field
            query_node = build_query_node(field, options)
            path.nil? ? query_node : Elastic::Nodes::Nested.build(with_prefix(path), query_node)
          end)
        end)
      end

      node.simplify
    end

    private

    def get_nesting_path(_field)
      dot_index = _field.rindex('.')
      return nil if dot_index.nil?
      _field.slice 0, dot_index
    end

    def build_query_node(_field, _options)
      _field = with_prefix _field
      _options = prepare_options _field, _options

      type = infer_type_from_params(_options)
      send("build_#{type}", _field, _options)
    end

    def infer_type_from_params(_query)
      return :term if _query.key? :term
      return :term if _query.key? :terms
      return :match if _query.key? :matches
      return :range if _query.key? :gte
      return :range if _query.key? :gt
      return :range if _query.key? :lte
      return :range if _query.key? :lt
      return :nested if _query.key? :nested
      nil
    end

    def with_prefix(_path)
      return _path if prefix.nil?
      "#{prefix}.#{_path}"
    end

    def prepare_options(_field, _options)
      properties = index.mapping.get_field_options _field.to_s
      raise ArgumentError, "field not mapped: #{_field}" if properties.nil?

      case properties['type']
      when 'nested'
        prepare_nested_options _options, properties
      when 'string'
        prepare_string_options _options, properties
      else
        prepare_default_options _options, properties
      end
    end

    def prepare_nested_options(_options, _properties)
      return _options if _options.is_a?(Hash) && _options[:nested]
      { nested: _options }
    end

    def prepare_string_options(_options, _properties)
      return _options if _options.is_a? Hash
      _properties['index'] == 'not_analyzed' ? { term: _options } : { matches: _options }
    end

    def prepare_default_options(_options, _properties)
      return _options if _options.is_a? Hash
      return range_to_options(_options) if _options.is_a? Range
      { term: _options }
    end

    def build_nested(_field, _options)
      query = _options[:nested]
      query = [query] unless query.is_a? Array

      nested_query = BuildQueryFromParams.for(index: index, params: query, prefix: _field)
      Elastic::Nodes::Nested.build _field, nested_query
    end

    def build_term(_field, _options)
      terms = Array(_options.fetch(:term, _options[:terms]))

      Elastic::Nodes::Term.new.tap do |node|
        node.field = _field
        node.mode = _options[:mode]
        node.terms = terms.map { |t| prep(_field, t) }
      end
    end

    def build_range(_field, _options)
      Elastic::Nodes::Range.new.tap do |node|
        node.field = _field
        node.gte = prep(_field, _options[:gte]) if _options.key? :gte
        node.gt = prep(_field, _options[:gt]) if _options.key? :gt
        node.lte = prep(_field, _options[:lte]) if _options.key? :lte
        node.lt = prep(_field, _options[:lt]) if _options.key? :lt
      end
    end

    def build_match(_field, _options)
      Elastic::Nodes::Match.new.tap do |node|
        node.field = _field
        node.query = prep(_field, _options[:matches])
      end
    end

    def range_to_options(_range)
      {
        gte: _range.begin,
        (_range.exclude_end? ? :lt : :lte) => _range.end
      }
    end

    def prep(_field, _value)
      index.definition.get_field(_field).prepare_value_for_query(_value)
    end
  end
end
