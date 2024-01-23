module Elastic::Commands
  class BuildSortFromParams < Elastic::Support::Command.new(:index, :params)
    def perform
      params.each do |param|
        case param
        when Hash
          param.each { |field, options| add_sort field, options }
        else
          add_sort param
        end
      end

      node.add_score_sort
      node
    end

    private

    def node
      @node ||= Elastic::Nodes::Sort.new
    end

    def add_sort(_field, _options = {})
      _field = _field.to_s
      _options = { order: _options } unless _options.is_a? Hash

      raise ArgumentError, "field not mapped: #{_field}" unless index.definition.has_field? _field

      path = parse_nesting_path(_field)
      raise NotImplementedError, "nested fields not yet supported in sorting" if path

      node.add_sort(_field, **_options)
    end

    def parse_nesting_path(_field)
      dot_index = _field.rindex('.')
      return nil if dot_index.nil?
      _field.slice(0, dot_index)
    end
  end
end
