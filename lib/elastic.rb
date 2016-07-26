require "elasticsearch"

require "elastic/version"
require "elastic/configuration"

require "elastic/support/command"
require "elastic/support/transform"
require "elastic/support/traversable"

require "elastic/commands/import_index_documents"
require "elastic/commands/build_query_from_params"

require "elastic/results/base"
require "elastic/results/aggregations"
require "elastic/results/hit"
require "elastic/results/hit_collection"
require "elastic/results/metric"
require "elastic/results/bucket_collection"
require "elastic/results/bucket"
require "elastic/results/grouped_result"
require "elastic/results/result_group"
require "elastic/results/root"

require "elastic/nodes/base"
require "elastic/nodes/base_agg"
require "elastic/nodes/boostable"
require "elastic/nodes/aggregable"
require "elastic/nodes/bucketed"
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
require "elastic/nodes/agg/top_hits"

require "elastic/shims/populating"
require "elastic/shims/grouping"

require "elastic/fields/value"
require "elastic/fields/nested"

require "elastic/core/definition"
require "elastic/core/adaptor"
require "elastic/core/mapping_manager"
require "elastic/core/serializer"
require "elastic/core/middleware"
require "elastic/core/base_middleware"
require "elastic/core/default_middleware"
require "elastic/core/source_formatter"
require "elastic/core/query_config"

require "elastic/dsl/bool_query_builder"
require "elastic/dsl/bool_query_context"

require "elastic/types/base_type"
require "elastic/types/faceted_type"
require "elastic/types/nestable_type"
require "elastic/type"
require "elastic/nested_type"

module Elastic
  def self.configure(*_args)
    Configuration.configure(*_args)
  end

  def self.register_middleware(_middleware)
    Core::Middleware.register _middleware
  end
end

require "elastic/railtie" if defined? Rails
