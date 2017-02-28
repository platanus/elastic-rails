RSpec.configure do |config|
  config.before(:example) do |example|
    if example.metadata[:elasticsearch]
      Elastic.drop
      Elastic.migrate
      Elastic.config.disable_indexing = false
      Elastic.config.disable_index_name_caching = true
    else
      Elastic.config.disable_indexing = true
    end
  end
end
