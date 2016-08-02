module Elastic::Core
  class QueryAssembler
    def initialize(_index, _config)
      @index = _index
      @config = _config
    end

    def assemble
      populated_query build_hit_query
    end

    def assemble_total
      query = build_base_query
      query.size = 0

      if grouped?
        attach_groups(query)
        query = grouped_query query
      end

      pick_query_totals query
    end

    def assemble_ids
      pick_query_ids build_hit_query
    end

    def assemble_pick(_field)
      pick_query_fields build_hit_query, _field
    end

    def assemble_metric(_node)
      query = assemble_metrics([_node])
      reduced_query query
    end

    def assemble_metrics(_aggs)
      query = build_base_query
      query.size = 0

      last = attach_groups(query)
      last.aggs = _aggs

      query = grouped_query(query) if grouped?
      query
    end

    private

    def build_base_query
      @config.root.simplify
    end

    def build_hit_query
      query = build_base_query

      if !grouped?
        query.size = (@config.limit || Elastic::Configuration.page_size)
        query.offset = @config.offset
      else
        query.size = 0
        last = attach_groups query
        last.aggregate(Elastic::Nodes::TopHits.build('default'))

        query = grouped_query query
        query = reduced_query query
      end

      query
    end

    def grouped?
      !@config.groups.empty?
    end

    def attach_groups(_query)
      @config.groups.inject(_query) do |last, node|
        node = node.simplify
        last.aggregate node
        node
      end
    end

    def grouped_query(_query)
      Elastic::Shims::Grouping.new(_query)
    end

    def reduced_query(_query)
      Elastic::Shims::Reducing.new(_query)
    end

    def populated_query(_query)
      Elastic::Shims::Populating.new(@index, @config, _query)
    end

    def pick_query_ids(_query)
      Elastic::Shims::IdPicking.new(_query)
    end

    def pick_query_fields(_query, _field)
      Elastic::Shims::FieldPicking.new(_query, _field.to_s)
    end

    def pick_query_totals(_query)
      Elastic::Shims::TotalPicking.new(_query)
    end
  end
end
