RSpec.configure do |config|
  def spec_es_client
    @spec_es_client ||= Elasticsearch::Client.new(
      host: ENV['ELASTICSEARCH_HOST'],
      port: ENV['ELASTICSEARCH_PORT']
    )
  end

  def spec_es_index
    'elastic_gem_specs'
  end

  config.before(:example) do
    allow(Elastic::Configuration).to receive(:api_client).and_return spec_es_client
    allow(Elastic::Configuration).to receive(:index_name).and_return spec_es_index
  end

  config.after(:example) do
    spec_es_client.indices.delete(index: spec_es_index + '*')
  end
end