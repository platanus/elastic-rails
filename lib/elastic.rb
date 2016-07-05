require "elasticsearch"
require "active_support/all"
require "elastic/version"
require "elastic/configuration"

require "elastic/support/transform"

require "elastic/commands/command"
require "elastic/commands/infer_field_options"
require "elastic/commands/import_index_documents"

require "elastic/nodes/base"
require "elastic/nodes/queries/term"
require "elastic/nodes/queries/range"
require "elastic/nodes/compound/and"
require "elastic/nodes/compound/or"
require "elastic/nodes/compound/boolean"
require "elastic/nodes/compound/function_score"
require "elastic/nodes/join/nested"

require "elastic/fields/value"
require "elastic/fields/nested"

require "elastic/core/definition"
require "elastic/core/adaptor"
require "elastic/core/mapping_manager"
require "elastic/core/serializer"

require "elastic/types/base_type"
require "elastic/types/faceted_type"
require "elastic/types/nestable_type"
require "elastic/type"
require "elastic/nested_type"

# require "elastic/histogram"
# require "elastic/indexable"
# require "elastic/indexable_record"

module Elastic
  extend self

  def connect(_index = nil)
    Elastic::Index.new api_client, (_index || default_index).to_s
  end

  def truncate(_index = nil)
    connect(_index).truncate
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
