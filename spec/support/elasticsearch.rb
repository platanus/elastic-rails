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

  config.after(:example) do
    spec_es_client.indices.delete(index: spec_es_index + '*')
  end
end
