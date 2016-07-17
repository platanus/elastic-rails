require "elasticsearch"

require "elastic/version"
require "elastic/configuration"

require "elastic/support/command"
require "elastic/support/transform"

require "elastic/commands/import_index_documents"
require "elastic/commands/build_query_from_params"

require "elastic/nodes/base"
require "elastic/nodes/base_with_boost"
require "elastic/nodes/search"
require "elastic/nodes/queries/term"
require "elastic/nodes/queries/range"
require "elastic/nodes/queries/match"
require "elastic/nodes/compound/and"
require "elastic/nodes/compound/or"
require "elastic/nodes/compound/boolean"
require "elastic/nodes/modifiers/function_score"
require "elastic/nodes/join/nested"
require "elastic/nodes/agg/base_metric"
require "elastic/nodes/agg/stats"
require "elastic/nodes/agg/average"
require "elastic/nodes/agg/minimum"
require "elastic/nodes/agg/maximum"
require "elastic/nodes/agg/sum"
require "elastic/nodes/agg/terms"
require "elastic/nodes/agg/date_histogram"

require "elastic/fields/value"
require "elastic/fields/nested"

require "elastic/core/definition"
require "elastic/core/adaptor"
require "elastic/core/mapping_manager"
require "elastic/core/serializer"
require "elastic/core/middleware"
require "elastic/core/base_middleware"
require "elastic/core/default_middleware"
require "elastic/core/hit"
require "elastic/core/source_formatter"
require "elastic/core/result"

require "elastic/dsl/bool_query_builder"
require "elastic/dsl/bool_query_context"

require "elastic/types/base_type"
require "elastic/types/faceted_type"
require "elastic/types/nestable_type"
require "elastic/type"
require "elastic/nested_type"
require "elastic/query"

module Elastic
  def self.configure(*_args)
    Configuration.configure(*_args)
  end

  def self.register_middleware(_middleware)
    Core::Middleware.register _middleware
  end
end

require "elastic/railtie" if defined? Rails
