module Elastic::Core
  class QueryConfig
    attr_accessor :query, :groups, :limit, :offset, :sort, :middleware_options

    def self.initial_config
      new.tap do |config|
        config.query = Elastic::Nodes::Boolean.new
        config.groups = []
        config.middleware_options = HashWithIndifferentAccess.new
      end
    end

    def clone
      self.class.new.tap do |clone|
        clone.query = @query.clone
        clone.groups = @groups.dup
        clone.limit = @limit
        clone.offset = @offset
        clone.sort = @sort.try(:clone)
        clone.middleware_options = @middleware_options.dup
      end
    end
  end
end
