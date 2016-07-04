module Elastic
  module Configuration
    extend self

    def api_client
      @api_client ||= load_api_client
    end

    def index_name
      config['index']
    end

    def strict_mode
      true
    end

    private

    def config
      @config ||= Rails.application.config_for(:elastic)
    end

    def load_api_client
      uri = config['url'] ? URI(config['url']) : nil
      Elasticsearch::Client.new(
        host: uri ? uri.host : config['host'],
        port: uri ? uri.port : config['port']
      )
    end
  end
end