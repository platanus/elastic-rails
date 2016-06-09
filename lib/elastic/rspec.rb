RSpec.configure do |config|
  config.before(:example, elasticsearch: true) do
    Elastic.truncate
  end
end