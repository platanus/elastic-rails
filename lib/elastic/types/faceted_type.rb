module Elastic::Types
  module FacetedType
    def fields(*_fields)
      raise ArgumentError, 'must provide at least a field name' if _fields.empty?

      options = {}
      options = _fields.pop if _fields.last.is_a? Hash

      _fields.each { |name| field(name, options) }
    end

    def field(_name, _options = {})
      pre_definition.register_field Elastic::Fields::Value.new(_name, _options)
    end
  end
end
