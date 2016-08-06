module Elastic::Core
  class Definition
    attr_reader :middleware_options

    def main_target
      targets.first
    end

    def targets
      @target_cache ||= load_targets.freeze
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

    def initialize
      @targets = []
      @field_map = {}
      @frozen = false
      @middleware_options = HashWithIndifferentAccess.new
    end

    def register_field(_field)
      raise 'definition has been frozen' if @frozen
      @field_map[_field.name] = _field
    end

    def fields
      @field_map.each_value
    end

    def expanded_field_names
      @expanded_field_names ||= @field_map.map { |_, field| field.expanded_names }.flatten
    end

    def freeze
      unless @frozen
        complete_and_validate_fields
        freeze_fields
        @middleware_options.freeze
        @frozen = true
      end
    end

    def frozen?
      !!@frozen
    end

    def get_field(_name)
      ensure_frozen!

      _name = _name.to_s
      separator = _name.index '.'
      if separator.nil?
        @field_map[_name]
      else
        parent = @field_map[_name[0...separator]]
        parent.try(:get_field, _name[separator + 1..-1])
      end
    end

    def has_field?(_name)
      ensure_frozen!

      !get_field(_name).nil?
    end

    def as_es_mapping
      ensure_frozen!

      properties = {}
      @field_map.each_value do |field|
        properties[field.name] = field.mapping_options
      end

      { 'properties' => properties.as_json }
    end

    private

    def load_targets
      mode = nil
      @targets.map do |target|
        target = target.to_s.camelize.constantize if target.is_a?(Symbol) || target.is_a?(String)

        target = load_target_middleware(target) unless target.class < BaseMiddleware
        raise 'index target is not indexable' if target.nil?
        raise 'mistmatching indexable mode' if mode && mode != target.mode
        mode = target.mode

        target
      end
    end

    def complete_and_validate_fields
      @field_map.each_value do |field|
        field.merge! infer_mapping_options(field.name) if field.needs_inference?

        error = field.validate
        raise error unless error.nil?
      end
    end

    def ensure_frozen!
      raise 'definition needs to be frozen' unless @frozen
    end

    def freeze_fields
      @field_map.each_value(&:freeze)
    end

    def load_target_middleware(_target)
      Middleware.wrap(_target)
    end

    def infer_mapping_options(_name)
      main_target.field_options_for(_name, middleware_options)
    end
  end
end
