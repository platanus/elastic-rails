module Elastic
  class IndexGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("../templates", __FILE__)

    desc "This generator creates a new model index definition at app/indices"
    def create_index
      template('index.rb', "app/indices/#{file_name.underscore}_index.rb")
    end
  end
end