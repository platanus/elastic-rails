module Elastic::Core
  class Definition
    attr_reader :middleware_options

    def main_target
      targets.first
    end

    def targets
      @target_cache ||= load_targets
    end

    def targets=(_values)
      @target_cache = nil
      @targets = _values
    end

    def types
      targets.map(&:type_name)
    end

    def mode
      main_target.mode
    end

    def initialize()
      @targets = []
      @field_map = {}
      @frozen = false
      @middleware_options = HashWithIndifferentAccess.new
    end

    def register_field(_field)
      raise RuntimeError, 'definition has been frozen' if @frozen
      @field_map[_field.name] = _field
    end

    def fields
      @field_map.each_value
    end

    def expanded_field_names
      @expanded_field_names ||= @field_map.map { |name, field| field.expanded_names }.flatten
    end

    def get_field(_name)
      _name = _name.to_s
      separator = _name.index '.'
      if separator.nil?
        @field_map[_name]
      else
        parent = @field_map[_name[0...separator]]
        parent.try(:get_field, _name[separator+1..-1])
      end
    end

    def has_field?(_name)
      !get_field(_name).nil?
    end

    def as_es_mapping
      # TODO: Make this a command
      properties = {}
      @field_map.each_value do |field|
        field_def = field.mapping_options

        if !field_def.key?(:type) && field.mapping_inference_enabled?
          inferred = infer_mapping_options(field.name)
          field_def.merge! inferred.symbolize_keys unless inferred.nil?
        end

        if Elastic::Configuration.strict_mode && !field_def.key?(:type)
          raise RuntimeError, "explicit field type for #{field} required"
        end

        properties[field.name] = field_def if field_def.key? :type
      end

      { 'properties' => properties.as_json }
    end

    def freeze
      unless @frozen
        @field_map.each_value(&:freeze)
        @frozen = true
        @middleware_options.freeze
      end
    end

    def frozen?
      !!@frozen
    end

    private

    def load_targets
      mode = nil
      @targets.map do |target|
        target = target.to_s.camelize.constantize if target.is_a?(Symbol) || target.is_a?(String)

        target = load_target_middleware(target) unless target.class < BaseMiddleware
        raise 'Index target is not indexable' if target.nil?
        raise 'Mistmatching indexable mode' if mode && mode != target.mode
        mode = target.mode

        target
      end.freeze
    end

    def load_target_middleware(_target)
      Middleware.wrap(_target)
    end

    def infer_mapping_options(_name)
      main_target.field_options_for(_name, middleware_options)
    end
  end
end
