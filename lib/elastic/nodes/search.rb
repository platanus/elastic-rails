module Elastic::Nodes
  class Search < Base
    attr_accessor :query, :size, :offset

    def self.build(_query)
      new.tap { |n| n.query = _query }
    end

    def initialize
      @size = size || Elastic::Configuration.page_size
      @offset = offset
      @fields = nil
    end

    def fields
      return nil if @fields.nil?
      @fields.each
    end

    def fields=(_values)
      @fields = _values.nil? ? nil : _values.dup.to_a
    end

    def clone
      clone_with_query @query.clone
    end

    def render
      {
        "size" => @size,
        "query" => @query.render
      }.tap do |options|
        options["_source"] = @fields unless @fields.nil?
        options["from"] = @offset unless offset == 0
      end
    end

    def simplify
      clone_with_query @query.simplify
    end

    private

    def clone_with_query(_query)
      base_clone.tap do |clone|
        clone.query = _query
        clone.size = @size
        clone.offset = @offset
        clone.fields = @fields
      end
    end
  end
end
