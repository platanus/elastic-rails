RSpec.configure do |config|
  config.before(:example) do |example|
    if example.metadata[:elasticsearch]
      Elastic.drop
      Elastic.migrate
      Elastic.config.disable_indexing = false
    else
      Elastic.config.disable_indexing = true
    end
  end
end
