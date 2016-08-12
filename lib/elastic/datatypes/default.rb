module Elastic::Datatypes
  class Default
    MAPPING_OPTIONS = [
      :type, :analyzer, :boost, :coerce, :copy_to, :doc_values, :dynamic,
      :enabled, :fielddata, :geohash, :geohash_precision, :geohash_prefix, :format, :ignore_above,
      :ignore_malformed, :include_in_all, :index_options, :lat_lon, :index, :fields, :norms,
      :null_value, :position_increment_gap, :properties, :search_analyzer, :similarity, :store,
      :term_vector
    ]

    def initialize(_name, _options)
      @name = _name
      @user_options = _options
    end

    def mapping_options
      @user_options.slice(*MAPPING_OPTIONS)
    end

    def prepare_for_query(_value)
      prepare_for_index _value
    end

    def prepare_for_index(_value)
      _value
    end

    def prepare_value_for_result(_value)
      _value
    end

    def supported_aggregations
      [
        { type: 'terms', size: 0 },
        { type: 'histogram' },
        { type: 'range' }
      ]
    end

    def supported_queries
      [:term, :range]
    end

    private

    attr_reader :name, :user_options
  end
end
