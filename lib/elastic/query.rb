module Elastic
  class Query
    extend Forwardable
    include Enumerable
    include Dsl::BoolQueryBuilder
    include Dsl::MetricBuilder

    def_delegators :result, :[], :each, :each_with_score, :count, :first, :last

    attr_reader :index

    def initialize(_index, _query_config = nil)
      @index = _index
      @config = _query_config || build_base_config
    end

    def limit(_size)
      with_clone { |config| config.limit = _size }
    end
    alias :size :limit

    def offset(_offset)
      with_clone { |config| config.offset = _offset }
    end

    def sort(*_params)
      with_clone do |config|
        config.sort = Commands::BuildSortFromParams.for(index: index, params: _params)
      end
    end

    def segment(*_params)
      with_clone do |config|
        config.groups << Commands::BuildAggFromParams.for(index: index, params: _params)
      end
    end

    def ids
      execute assembler.assemble_ids
    end

    def pick(_field)
      execute assembler.assemble_pick(_field)
    end

    def total
      execute assembler.assemble_total
    end

    def result(_reset = false)
      @result = nil if _reset
      @result ||= execute(assembler.assemble)
    end

    def as_query_node
      @config.query.clone
    end

    def as_es_query
      assembler.assemble.render
    end

    def compose(&_block)
      agg_nodes = []
      Dsl::ResultComposer.new(agg_nodes).tap(&_block)
      execute assembler.assemble_metrics agg_nodes
    end

    def aggregate(_node)
      execute assembler.assemble_metric _node
    end

    def initial_scroll(_scroll = "1m")
      execute(assembler.assemble, _scroll)
    end

    def scroll_after(_scroll_id, _scroll = "1m")
      query = assembler.assemble
      raw = @index.connector.scroll_query(scroll_id: _scroll_id, scroll: _scroll)
      query.handle_result(raw, formatter)
    end

    private

    def with_clone(&_block)
      new_config = @config.clone
      _block.call(new_config)
      self.class.new(@index, new_config)
    end

    def with_bool_query(&_block)
      with_clone { |config| _block.call(config.query) }
    end

    def build_base_config
      Core::QueryConfig.initial_config
    end

    def execute(_query, _scroll = nil)
      raw = @index.connector.query(query: _query.render, scroll: _scroll)
      _query.handle_result(raw, formatter)
    end

    def assembler
      Core::QueryAssembler.new(@index, @config)
    end

    def formatter
      Core::SourceFormatter.new(@index.definition)
    end
  end
end
