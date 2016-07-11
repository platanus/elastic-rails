require "elastic/railties/utils"
require "elastic/railties/ar_helpers"
require "elastic/railties/indexable_record"

module Elastic
  class Railtie < Rails::Railtie
    initializer "elastic.configure_rails_initialization" do |app|
      Elastic.configure Rails.application.config_for(:elastic)

      # Make every model indexable
      ActiveRecord::Base.send(:include, Elastic::Railties::IndexableRecord)
    end

    rake_tasks do
      load File.expand_path('../railties/tasks/es.rake', __FILE__)
    end

    # TODO: configure generators here too
  end
end

# Expose railties utils at Elastic namespace
module Elastic
  extend Elastic::Railties::Utils
end
