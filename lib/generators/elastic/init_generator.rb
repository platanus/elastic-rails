module Elastic
  class InitGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    desc "Initializes the app to work with elastic-rails"
    def create_index
      template("elastic.yml", "config/elastic.yml")
    end
  end
end
