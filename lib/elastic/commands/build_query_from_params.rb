module Elastic::Commands
  class BuildQueryFromParams < Elastic::Support::Command.new(:index, :params)
    def perform
      node = Elastic::Nodes::Or.new(params.map do |part|
        Elastic::Nodes::And.new(part.map do |field, options|
          field = field.to_s
          path = get_nesting_path field
          query_node = build_query_node(field, options)
          path.nil? ? query_node : Elastic::Nodes::Nested.new(path, query_node)
        end.to_a)
      end.to_a)

      node.simplify
    end

    private

    def get_nesting_path(_field)
      dot_index = _field.rindex('.')
      return nil if dot_index.nil?
      return _field.slice(0, dot_index)
    end

    def build_query_node(_field, _options)
      raise ArgumentError, "field not mapped: #{_field}" unless index.definition.has_field? _field
      _options = infer_options(_field, _options) unless _options.is_a? Hash

      type = _options[:type]
      type = infer_type_from_params(_options) if type.nil?

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
      return nil
    end

    def infer_options(_field, _query)
      properties = index.mapping.get_field_options _field.to_s
      case properties['type']
      when 'string'
        properties['index'] == 'not_analyzed' ? { term: _query } : { matches: _query }
      else
        return range_to_options(_query) if _query.is_a? Range
        return { term: _query }
      end
    end

    def build_term(_field, _options)
      terms = Array(_options[:term] || _options[:terms])
      terms = terms.map { |t| prep(_field, t) }
      Elastic::Nodes::Term.new _field, terms
    end

    def build_range(_field, _options)
      Elastic::Nodes::Range.new(_field).tap do |node|
        node.gte = prep(_field, _options[:gte]) if _options.key? :gte
        node.gt = prep(_field, _options[:gt]) if _options.key? :gt
        node.lte = prep(_field, _options[:lte]) if _options.key? :lte
        node.lt = prep(_field, _options[:lt]) if _options.key? :lt
      end
    end

    def build_match(_field, _options)
      Elastic::Nodes::Match.new(_field, prep(_field, _options[:matches]))
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