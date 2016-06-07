module Elastic
  class Type
    MAPPING_OPTIONS = [ :type, :analyzer, :boost, :coerce, :copy_to, :doc_values, :dynamic,
      :enabled, :fielddata, :geohash, :geohash_precision, :geohash_prefix, :format, :ignore_above,
      :ignore_malformed, :include_in_all, :index_options, :lat_lon, :index, :fields, :norms,
      :null_value, :position_increment_gap, :properties, :search_analyzer, :similarity, :store,
      :term_vector ]

    def self.connection
      @connection ||= Elastic.connect index
    end

    def self.index=(_value)
      @index = _value
    end

    def self.index
      @index
    end

    def self.type_name=(_value)
      @type_name = _value
    end

    def self.type_name
      @type_name ||= to_s.underscore
    end

    def self.fields(*_fields)
      raise ArgumentError, 'must provide at least a field name' if _fields.length == 0

      options = {}
      options = _fields.pop if _fields.last.is_a? Hash

      _fields.each do |name|
        register_field(name, options)
        register_mapping(name, options)
        register_transform(name, options[:transform]) if options.key? :transform
      end
    end

    def self.field(_field, _options)
      fields(_field, _options)
    end

    def self.store(_data, _options = {})
      connection.index(type_name, new(_data).render, mapping: { type_name => type_mapping })
    end

    def self.store_bulk(_collection, _options = {})
      # TODO
    end

    def self.query(_query)
      connection.query type_name, _query
    end

    def self.clear(_options = {})
      connection.clear type_name
    end

    def self.prepare_field_for_query(_field, _value)
      transform = transforms[_field.to_sym]
      transform.nil? ? _value : transform.apply(_value)
    end

    attr_reader :object

    def initialize(_object)
      @object = _object
    end

    def render
      document = {}
      document[:id] = fetch_object_property(:id) if object_has_property?(:id)

      self.class.type_fields.each do |name, options|
        document[name] = fetch_object_property(name)
      end

      document
    end

    private

    def self.type_fields
      @type_fields ||= []
    end

    def self.type_mapping
      @type_mapping ||= { "properties" => { } }
    end

    def self.transforms
      @transforms ||= { }
    end

    def self.register_field(_name, _options)
      type_fields << [_name.to_sym, _options]
    end

    def self.register_mapping(_name, _options)
      field = _options.slice(*MAPPING_OPTIONS)
      field.merge! type: 'string', index: 'not_analyzed' if _options[:type].try(:to_sym) == :term
      type_mapping["properties"][_name.to_s] = field if field.length > 0
    end

    def self.register_transform(_name, _transform)
      transforms[_name.to_sym] = ValueTransform.new self, _transform
    end

    def object_has_property?(_name)
      self.respond_to?(_name) || object.respond_to?(_name)
    end

    def fetch_object_property(_name)
      value = self.respond_to?(_name) ? public_send(_name) : object.public_send(_name)
      self.class.prepare_field_for_query _name, value
    end
  end
end
