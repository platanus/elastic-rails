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
    Elastic.config.reset.assign_attributes(
      api_client: spec_es_client,
      index: spec_es_index
    )
  end

  config.around(:example) do |example|
    spec_es_client.indices.delete(index: spec_es_index + '*')
    example.run
  end

  def es_index_count(_index)
    spec_es_client.indices.refresh index: _index
    spec_es_client.count(index: _index)['count']
  end

  def es_find_by_id(_index, _id)
    spec_es_client.indices.refresh index: _index
    spec_es_client.get index: _index, id: _id
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    nil
  end

  def es_index_exists?(_index)
    spec_es_client.indices.exists? index: _index
  end

  def es_index_mapping(_index)
    mappings = spec_es_client.indices.get_mapping index: _index, include_type_name: false
    mappings = mappings.values.first
    return nil if mappings.nil?

    mappings['mappings']
  end

  def es_indexes_for_alias(_alias)
    result = spec_es_client.indices.get_alias(name: _alias)
    result.keys
  end
end
