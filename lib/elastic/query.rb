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

    def coord_similarity(_enable)
      with_clone { |config| config.root.query.disable_coord = !_enable }
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

    def ids(_type = nil)
      execute assembler.assemble_ids
    end

    def pick(_field)
      execute assembler.assemble_pick(_field)
    end

    def aggregate(_name = nil, _node = nil, &_block)
      # TODO
    end

    def total
      execute assembler.assemble_total
    end

    def result(_reset = false)
      @result = nil if _reset
      @result ||= execute(assembler.assemble)
    end

    def as_es_query
      assembler.assemble.render
    end

    private

    def with_clone(&_block)
      new_config = @config.clone
      _block.call(new_config)
      self.class.new(@index, new_config)
    end

    def with_bool_query(&_block)
      with_clone { |config| _block.call(config.root.query) }
    end

    def with_aggregable_for_metric(&_block)
      adaptor = AggregableAdaptor.new.tap(&_block)
      execute assembler.assemble_metric(adaptor.agg)
    end

    def build_base_config
      Core::QueryConfig.initial_config
    end

    def assembler
      @assembler ||= Core::QueryAssembler.new(@index, @config)
    end

    def execute(_query)
      _query.handle_result @index.adaptor.query(
        type: @index.definition.types,
        query: _query.render
      )
    end

    class AggregableAdaptor
      attr_accessor :agg

      def aggregate(_node)
        self.agg = _node
      end
    end
  end
end
