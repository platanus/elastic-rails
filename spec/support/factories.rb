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

  def build_node(_string, _boost = nil)
    Class.new(Elastic::Nodes::BaseWithBoost) do
      def initialize(_query, _boost)
        @query = _query
        self.boost = _boost
      end

      def clone
        self.class.new @query, boost
      end

      def render
        @query
      end

      def simplify
        clone
      end
    end.new(_string, _boost)
  end
end