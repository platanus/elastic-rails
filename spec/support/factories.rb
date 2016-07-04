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
      allow(double).to receive(:as_es_mapping).and_return(mapping)
      allow(double).to receive(:fields).and_return(fields)
      allow(double).to receive(:expanded_field_names).and_return(expanded_fields)
    end
  end
end