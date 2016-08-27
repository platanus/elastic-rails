module Elastic
  class Configuration
    DEFAULTS = {
      host: '127.0.0.1',
      port: 9200,
      page_size: 20,
      coord_similarity: true,
      import_batch_size: 10_000,
      whiny_indices: false,
      api_client: nil, # set by method
      logger: nil # set by method
    }

    attr_accessor :host, :port, :api_client, :index, :page_size, :coord_similarity, :logger,
      :import_batch_size, :whiny_indices

    def initialize
      assign_attributes DEFAULTS
    end

    def reset
      assign_attributes DEFAULTS
    end

    def assign_attributes(_options)
      _options.each { |k, v| public_send("#{k}=", v) }
      self
    end

    def api_client
      @api_client || default_api_client
    end

    def logger
      @logger || default_logger
    end

    private

    def default_api_client
      @default_api_client ||= Elasticsearch::Client.new host: @host, port: @port
    end

    def default_logger
      @default_logger ||= Logger.new(STDOUT)
    end
  end
end
