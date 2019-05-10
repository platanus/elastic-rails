module Elastic::Core
  class Definition
    attr_reader :middleware_options

    def target
      raise 'attempting to access target before definition has been frozen' if @target_cache.nil?

      @target_cache
    end

    def target=(_value)
      @target = _value
    end

    def mode
      target.mode
    end

    def initialize
      @target = nil
      @field_map = {}
      @field_cache = {}
      @middleware_options = HashWithIndifferentAccess.new
    end

    def register_field(_field)
      @field_map[_field.name] = _field
    end

    def fields
      @field_map.each_value
    end

    def freeze
      return if frozen?

      cache_target
      complete_and_validate_fields
      freeze_fields
      @middleware_options.freeze
      super
    end

    def get_field(_name)
      ensure_frozen!

      _name = _name.to_s
      @field_cache[_name] = resolve_field(_name) unless @field_cache.key? _name
      @field_cache[_name]
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

    def resolve_field(_name)
      separator = _name.index '.'
      if separator.nil?
        @field_map[_name]
      else
        parent = @field_map[_name[0...separator]]
        return nil if parent.nil?

        parent.get_field(_name[separator + 1..-1])
      end
    end

    def cache_target
      target = @target
      target = target.to_s.camelize.constantize if @target.is_a?(Symbol) || @target.is_a?(String)
      target = load_target_middleware(target) unless target.class < BaseMiddleware

      raise 'index target is not indexable' if target.nil?

      @target_cache = target
    end

    def complete_and_validate_fields
      @field_map.each_value do |field|
        field.merge! infer_mapping_options(field.name) if field.needs_inference?

        error = field.validate
        raise error unless error.nil?
      end

      @field_map.freeze
    end

    def ensure_frozen!
      raise 'definition needs to be frozen' unless frozen?
    end

    def freeze_fields
      @field_map.each_value(&:freeze)
    end

    def load_target_middleware(_target)
      Middleware.wrap(_target)
    end

    def infer_mapping_options(_name)
      target.field_options_for(_name, middleware_options)
    end
  end
end
