RSpec.configure do |config|
  config.before(:example, elasticsearch: true) do
    Elastic.drop
    Elastic.migrate
  end
end
