require "elasticsearch"

require "elastic/version"
require "elastic/configuration"
require "elastic/errors"

require "elastic/support/command"
require "elastic/support/transform"
require "elastic/support/traversable"

require "elastic/commands/import_index_documents"
require "elastic/commands/build_query_from_params"
require "elastic/commands/build_agg_from_params"
require "elastic/commands/build_sort_from_params"
require "elastic/commands/compare_mappings"

require "elastic/results/base"
require "elastic/results/scored_item"
require "elastic/results/scored_collection"
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
require "elastic/nodes/search"
require "elastic/nodes/term"
require "elastic/nodes/range"
require "elastic/nodes/match"
require "elastic/nodes/and"
require "elastic/nodes/or"
require "elastic/nodes/boolean"
require "elastic/nodes/sort"
require "elastic/nodes/function_score"
require "elastic/nodes/nested"
require "elastic/nodes/agg/base_metric"
require "elastic/nodes/agg/stats"
require "elastic/nodes/agg/average"
require "elastic/nodes/agg/minimum"
require "elastic/nodes/agg/maximum"
require "elastic/nodes/agg/sum"
require "elastic/nodes/agg/terms"
require "elastic/nodes/agg/date_histogram"
require "elastic/nodes/agg/top_hits"

require "elastic/shims/base"
require "elastic/shims/populating"
require "elastic/shims/grouping"
require "elastic/shims/reducing"
require "elastic/shims/total_picking"
require "elastic/shims/id_picking"
require "elastic/shims/field_picking"

require "elastic/datatypes/default"
require "elastic/datatypes/string"
require "elastic/datatypes/term"
require "elastic/datatypes/date"
require "elastic/datatypes/time"

require "elastic/fields/value"
require "elastic/fields/nested"

require "elastic/core/connector"
require "elastic/core/definition"
require "elastic/core/serializer"
require "elastic/core/middleware"
require "elastic/core/base_middleware"
require "elastic/core/default_middleware"
require "elastic/core/source_formatter"
require "elastic/core/query_config"
require "elastic/core/query_assembler"

require "elastic/dsl/bool_query_builder"
require "elastic/dsl/bool_query_context"
require "elastic/dsl/metric_builder"

require "elastic/types/base_type"
require "elastic/types/faceted_type"
require "elastic/types/nestable_type"

require "elastic/type"
require "elastic/nested_type"
require "elastic/query"
require "elastic/nested_query"

module Elastic
  def self.config
    @config ||= Configuration.new
  end

  def self.logger
    config.logger
  end

  def self.configure(_options = nil, &_block)
    config.assign_attributes(_options) unless _options.nil?
    _block.call(config) unless _block.nil?
  end

  def self.register_middleware(_middleware)
    Core::Middleware.register _middleware
  end
end

require "elastic/railtie" if defined? Rails
