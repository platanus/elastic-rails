RSpec.configure do |config|
  def spec_es_index
    'elastic_gem_specs'
  end

  def spec_es_client
    @spec_es_client ||= Elasticsearch::Client.new(
      host: ENV['ELASTICSEARCH_HOST'],
      port: ENV['ELASTICSEARCH_PORT']
    )
  end

  config.before(:example) do
    Elastic::Configuration.reset.configure(
      client: spec_es_client,
      index: spec_es_index
    )
  end

  config.around(:example) do |example|
    spec_es_client.indices.delete(index: spec_es_index + '*')
    example.run
  end

  def es_index_count(_index)
    spec_es_client.count(index: _index)['count']
  end

  def es_index_mappings(_index, _type = nil)
    mappings = spec_es_client.indices.get_mapping index: _index
    mappings = mappings.values.first
    return {} if mappings.nil?
    mappings = mappings['mappings']
    return mappings[_type] || {} if _type
    mappings
  end

  def es_indexes_for_alias(_alias)
    result = spec_es_client.indices.get_alias(name: _alias)
    result.keys
  end
end
