require "elasticsearch"

require "elastic/version"
require "elastic/railtie" if defined? Rails
require "elastic/configuration"

require "elastic/support/command"
require "elastic/support/transform"

require "elastic/commands/infer_field_options"
require "elastic/commands/import_index_documents"

require "elastic/nodes/base"
require "elastic/nodes/queries/term"
require "elastic/nodes/queries/range"
require "elastic/nodes/queries/match"
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
  def self.configure(*_args)
    Configuration.configure(*_args)
  end
end
