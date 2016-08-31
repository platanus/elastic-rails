require "elastic/railties/utils"
require "elastic/railties/ar_helpers"
require "elastic/railties/ar_middleware"
require "elastic/railties/configuration_extensions"
require "elastic/railties/type_extensions"
require "elastic/railties/query_extensions"
require "elastic/railties/jobs/indexing_job"
require "elastic/railties/jobs/deleting_job"
require "elastic/railties/indexable_record"

module Elastic
  class Railtie < Rails::Railtie
    initializer "elastic.configure_rails_initialization" do
      Elastic.configure Rails.application.config_for(:elastic).merge(
        time_zone: Rails.application.config.time_zone,
        logger: Rails.logger
      )

      # Make every activerecord model indexable
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

# Add activerecord related configuration parameters
class Elastic::Configuration
  include Elastic::Railties::ConfigurationExtensions
end

# Add activerecord related index helpers
class Elastic::Type
  include Elastic::Railties::TypeExtensions
end

# Add activerecord related query helpers
class Elastic::Query
  include Elastic::Railties::QueryExtensions
end

# Register active record middleware
Elastic.register_middleware Elastic::Railties::ARMiddleware
