module Elastic::Fields
  class Value
    extend Forwardable

    attr_reader :name

    def_delegators :@datatype, :mapping_options, :prepare_value_for_result, :supported_queries

    def initialize(_name, _options)
      @name = _name.to_s
      @options = _options.symbolize_keys
      @mapping_inference = true
    end

    def nested?
      false
    end

    def merge!(_options)
      return if _options.nil?
      @options.merge! _options.symbolize_keys
    end

    def get_field(_name)
      nil
    end

    def validate
      return "explicit field type for #{@name} required" unless @options.key? :type
      nil
    end

    def expanded_names
      [@name]
    end

    def needs_inference?
      mapping_inference_enabled? && !@options.key?(:type)
    end

    def disable_mapping_inference
      @mapping_inference = false
    end

    def freeze
      @name.freeze
      @options.freeze
      load_transform_and_datatype
    end

    def prepare_value_for_query(_value)
      _value = @transform.apply _value if @transform
      @datatype.prepare_for_query _value
    end

    def prepare_value_for_index(_value)
      _value = @transform.apply _value if @transform
      @datatype.prepare_for_index _value
    end

    def select_aggregation(_from)
      return @datatype.supported_aggregations.first if _from.nil?

      @datatype.supported_aggregations.find do |agg|
        _from.include? agg[:type].to_sym
      end.try(:dup)
    end

    def default_options_for_query(_query_type)
      method_name = "#{_query_type}_query_defaults"
      return {} unless @datatype.respond_to? method_name
      @datatype.public_send(method_name)
    end

    private

    def load_transform_and_datatype
      @datatype = datatype_class.new(@name, @options)
      @transform = Elastic::Support::Transform.new @options[:transform] if @options.key? :transform
    end

    def mapping_inference_enabled?
      @mapping_inference && !@options.key?(:transform)
    end

    def datatype_class
      case @options[:type]
      when Symbol, String
        load_registered_datatype @options[:type].to_sym
      when nil
        Elastic::Datatypes::Default
      else
        @options[:type]
      end
    end

    def load_registered_datatype(_name)
      # TODO: replace this with a datatype registry
      case _name
      when :term
        Elastic::Datatypes::Term
      when :string
        Elastic::Datatypes::String
      when :date
        Elastic::Datatypes::Date
      when :time
        Elastic::Datatypes::Time
      else
        Elastic::Datatypes::Default
      end
    end
  end
end
