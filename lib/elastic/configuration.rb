module Elastic
  module Configuration
    DEFAULT = {
      host: '127.0.0.1',
      port: 9200,
      page_size: 20,
      coord_similarity: true
    }

    extend self

    def reset
      @config = nil
      self
    end

    def configure(_options = nil, &_block)
      if _options.nil?
        _block.call self
      else
        @config = config.merge _options.symbolize_keys
      end
      self
    end

    def api_client
      config[:client] ||= load_api_client
    end

    def index_name
      config[:index]
    end

    def indices_path
      'app/indices'
    end

    def page_size
      @config[:page_size]
    end

    def coord_similarity
      @config[:coord_similarity]
    end

    def logger
      @config[:logger] || default_logger
    end

    private

    def config
      @config ||= DEFAULT
    end

    def default_logger
      @default_logger ||= Logger.new(STDOUT)
    end

    def load_api_client
      Elasticsearch::Client.new host: config[:host], port: config[:port]
    end
  end
end
