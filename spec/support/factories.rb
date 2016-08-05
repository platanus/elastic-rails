RSpec.configure do |config|
  DEFAULT_MAPPING = { 'properties' => {} }

  def definition_double(targets: [], mapping: DEFAULT_MAPPING, fields: [])
    fields = fields.map do |field|
      case field
      when String, Symbol
         Elastic::Fields::Value.new(field, {})
      else
        field
      end
    end

    expanded_fields = (mapping['properties'].keys + fields.map(&:name)).uniq

    double(Elastic::Core::Definition).tap do |double|
      allow(double).to receive(:targets).and_return(targets)
      allow(double).to receive(:types).and_return(targets.map(&:to_s))
      allow(double).to receive(:as_es_mapping).and_return(mapping)
      allow(double).to receive(:fields).and_return(fields)
      allow(double).to receive(:expanded_field_names).and_return(expanded_fields)
    end
  end

  def field_double(_name, _mapping = {}, _mapping_inference = true)
    double(:field).tap do |field|
      allow(field).to receive(:name).and_return _name.to_s
      allow(field).to receive(:expanded_names).and_return [_name.to_s]
      allow(field).to receive(:mapping_inference_enabled?).and_return _mapping_inference
      allow(field).to receive(:mapping_options).and_return _mapping
      allow(field).to receive(:has_field?).and_return false
      allow(field).to receive(:get_field).and_return nil
      allow(field).to receive(:freeze).and_return nil
    end
  end

  def formatter_double
    Class.new do
      def format(_source, _preffix)
        _source
      end

      def format_field(_field, _value)
        _value
      end
    end.new
  end

  def build_type(_name, *_columns)
    Class.new(Struct.new(*_columns.map(&:to_sym))) do
      define_singleton_method(:to_s) do
        _name
      end
    end
  end

  def build_index(_name, target: nil, migrate: false, &_block)
    klass = Class.new(Elastic::Type) do
      define_singleton_method(:to_s) do
        _name
      end
    end

    klass.class_exec(self, &_block) unless _block.nil?
    klass.target = target || build_type("#{_name}Target", *klass.definition.fields.map(&:name))
    klass.mapping.migrate if migrate
    klass
  end

  def build_nested_index(target: nil, &_block)
    klass = Class.new(Elastic::NestedType)

    klass.class_exec(self, &_block) unless _block.nil?
    klass.target = target || build_type("#{_name}Target", *klass.definition.fields.map(&:name))
    klass
  end

  def build_node(_query, base: nil)
    Class.new(base || Elastic::Nodes::Base) do
      include Elastic::Nodes::Concerns::Boostable

      def initialize(_query)
        @query = _query
      end

      def clone
        self.class.new @query
      end

      def render
        @query
      end

      def simplify
        clone
      end

      def handle_result(_raw, _formatter)
        Elastic::Results::Metric.new _raw
      end
    end.new(_query)
  end

  def build_agg_node(_name, _query)
    node = build_node(_query, base: Elastic::Nodes::BaseAgg)
    node.name = _name
    node
  end
end
