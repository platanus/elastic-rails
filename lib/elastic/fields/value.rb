module Elastic::Fields
  class Value
    MAPPING_OPTIONS = [ :type, :analyzer, :boost, :coerce, :copy_to, :doc_values, :dynamic,
      :enabled, :fielddata, :geohash, :geohash_precision, :geohash_prefix, :format, :ignore_above,
      :ignore_malformed, :include_in_all, :index_options, :lat_lon, :index, :fields, :norms,
      :null_value, :position_increment_gap, :properties, :search_analyzer, :similarity, :store,
      :term_vector ]

    attr_reader :name

    def initialize(_name, _options)
      @name = _name.to_s
      @options = _options
      @mapping_inference = true
      @transform = Elastic::Support::Transform.new @options[:transform]
    end

    def expanded_names
      [@name]
    end

    def mapping_inference_enabled?
      @mapping_inference && !@options.key?(:transform)
    end

    def disable_mapping_inference
      @mapping_inference = false
    end

    def mapping_options
      process_special_types @options.symbolize_keys.slice(*MAPPING_OPTIONS)
    end

    def has_field?(_name)
      false
    end

    def prepare_value_for_query(_value)
      prepare_value_for_index(_value)
    end

    def prepare_value_for_index(_value)
      @transform.apply _value
    end

    private

    def process_special_types(_definition)
      case _definition[:type].try(:to_sym)
      when :term
        _definition[:type] = 'string'
        _definition[:index] = 'not_analyzed'
      when :date
        _definition[:format] = 'dateOptionalTime' unless _definition.key? :format
      end

      _definition
    end
  end
end