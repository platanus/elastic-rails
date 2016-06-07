require "elasticsearch"
require "elastic/version"

require "elastic/capabilities/aggregation_builder"
require "elastic/capabilities/bool_query_builder"
require "elastic/capabilities/context_handler"

require "elastic/index"
require "elastic/type"
require "elastic/query"
require "elastic/histogram"
require "elastic/value_transform"
require "elastic/indexable"
require "elastic/indexable_record"

module Elastic
  extend self

  def connect(_index = nil)
    Elastic::Index.new api_client, (_index || default_index).to_s
  end

  private

  def config
    Rails.application.config_for(:elastic)
  end

  def default_index
    config['index']
  end

  def api_client
    @api_client ||= load_api_client
  end

  def load_api_client
    uri = config['url'] ? URI(config['url']) : nil
    Elasticsearch::Client.new(
      host: uri ? uri.host : config['host'],
      port: uri ? uri.port : config['port']
    )
  end
end
