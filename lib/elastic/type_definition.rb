module Elastic
  class TypeDefinition
    MAPPING_OPTIONS = [ :type, :analyzer, :boost, :coerce, :copy_to, :doc_values, :dynamic,
      :enabled, :fielddata, :geohash, :geohash_precision, :geohash_prefix, :format, :ignore_above,
      :ignore_malformed, :include_in_all, :index_options, :lat_lon, :index, :fields, :norms,
      :null_value, :position_increment_gap, :properties, :search_analyzer, :similarity, :store,
      :term_vector ]

    attr_accessor :name
    attr_reader :mapping

    def main_target
      targets.first
    end

    def targets
      @target_cache ||= load_targets
    end

    def fields
      @fields.each
    end

    def targets=(_values)
      @target_cache = nil
      @targets = _values
    end

    def initialize(_name, _default_target)
      @name = _name
      @targets = [_default_target]
      @fields = []
      @field_options = {}
      @transforms = {}
      @mapping = { "properties" => { } }
    end

    def register_field(_name, _options = {})
      _name = _name.to_s
      @fields << _name
      @field_options[_name] = _options
      add_field_to_mapping _name, _options
    end

    def has_field?(_name)
      @field_options.key? _name
    end

    def get_field_type(_name)
      options = @field_options.fetch(_name, {})
      options[:type] || infer_type_from_target(_name)
    end

    def prepare_field_for_query(_name, _value)
      options = @field_options.fetch(_name, {})
      apply_transform options[:transform], _value
    end

    private

    def load_targets
      @targets.map do |target|
        next target.to_s.camelize.constantize if target.is_a?(Symbol) || target.is_a?(String)
        target
      end
    end

    def add_field_to_mapping(_name, _options)
      field_def = _options.slice(*MAPPING_OPTIONS)

      # field types
      case _options[:type].try(:to_sym)
      when :term
        field_def.merge! type: 'string', index: 'not_analyzed'
      end

      @mapping["properties"][_name.to_s] = field_def if field_def.length > 0
    end

    def apply_transform(_transform, _value)
      case _transform
      when nil then _value
      when String, Symbol
       _value.public_send(_transform)
      else
        _value.instance_exec(&_transform)
      end
    end

    def infer_type_from_target(_name)
      if main_target.respond_to? :elastic_field_type
        main_target.elastic_field_type _name
      elsif main_target.respond_to? :columns_hash
        infer_type_from_ar_target _name
      else
        nil
      end
    end

    def infer_type_from_ar_target(_name)
      case main_target.columns_hash[_name].type
      when :text, :string     then :string
      when :integer           then :long # not sure..
      when :float, :decimal   then :double # not sure..
      when :datetime, :date   then :date
      when :boolean           then :boolean
      else nil end
    end
  end
end