module Elastic::Core
  class Connector
    def initialize(_name, _types, _mapping)
      @name = _name
      @types = _types
      @mapping = _mapping
    end

    def index_name
      @index_name ||= "#{Elastic.config.index}_#{@name}"
    end

    def read_index_name
      index_name
    end

    def write_index_name
      Thread.current[write_index_thread_override] || write_index_alias
    end

    def status
      actual_name = resolve_actual_index_name
      return :not_available if actual_name.nil?
      return :not_synchronized unless mapping_synchronized? actual_name
      :ready
    end

    def drop
      api.indices.delete index: "#{index_name}:*"
      nil
    end

    def remap
      case status
      when :not_available
        create_from_scratch
      when :not_synchronized
        begin
          setup_index_types resolve_actual_index_name
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          return false
        end
      end

      true
    end

    def migrate(batch_size: nil)
      unless remap
        rollover do
          copy_documents(read_index_name, write_index_name, batch_size || default_batch_size)
        end
      end

      nil
    end

    def index(_document)
      # TODO: validate document type

      api.index(
        index: write_index_name,
        id: _document['_id'],
        type: _document['_type'],
        body: _document['data']
      )
    end

    def bulk_index(_documents)
      # TODO: validate documents type

      body = _documents.map { |doc| { 'index' => doc } }

      retry_on_temporary_error('bulk indexing') do
        api.bulk(index: write_index_name, body: body)
      end
    end

    def refresh
      api.indices.refresh index: read_index_name
    end

    def find(_id, type: '_all')
      api.get(index: read_index_name, type: type, id: _id)
    end

    def count(query: nil, type: nil)
      api.count(index: read_index_name, type: type, body: query)['count']
    end

    def query(query: nil, type: nil)
      api.search(index: read_index_name, type: type, body: query)
    end

    def rollover(&_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      new_index = create_index_w_mapping
      tmp_index = create_index_w_mapping('tmp')
      actual_index = resolve_actual_index_name

      begin
        transfer_alias(write_index_alias, from: actual_index, to: tmp_index)

        perform_optimized_write_on(new_index, &_block)

        transfer_alias(index_name, from: actual_index, to: new_index)
        transfer_alias(write_index_alias, from: tmp_index, to: new_index)
        api.indices.delete index: actual_index if actual_index
      rescue
        transfer_alias(write_index_alias, from: tmp_index, to: actual_index)
        api.indices.delete index: new_index
      ensure
        # rollback
        # TODO: what would happen if the following fails? O.O
        copy_documents(tmp_index, write_index_name, small_batch_size)
        api.indices.delete index: tmp_index
        api.indices.refresh index: index_name
      end
    end

    private

    def api
      Elastic.config.api_client
    end

    def perform_optimized_write_on(_index)
      old_index = Thread.current[write_index_thread_override]
      Thread.current[write_index_thread_override] = _index
      configure_index(_index, refresh_interval: -1)
      yield
    ensure
      configure_index(_index, refresh_interval: '1s')
      Thread.current[write_index_thread_override] = old_index
    end

    def write_index_thread_override
      "_elastic_#{index_name}_write_index"
    end

    def write_index_alias
      @write_index_alias = "#{index_name}.w"
    end

    def resolve_actual_index_name
      result = api.indices.get_alias(name: index_name)
      result.keys.first
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def create_index_w_mapping(_role = 'main')
      new_name = "#{index_name}:#{_role}:#{Time.now.to_i}"
      api.indices.create index: new_name
      api.cluster.health wait_for_status: 'yellow'
      setup_index_types new_name
      new_name
    end

    def create_from_scratch
      new_index = create_index_w_mapping
      api.indices.update_aliases(
        body: {
          actions: [
            { add: { index: new_index, alias: index_name } },
            { add: { index: new_index, alias: write_index_alias } }
          ]
        }
      )
    end

    def mapping_synchronized?(_index)
      type_mappings = api.indices.get_mapping(index: _index)
      return false if type_mappings[_index].nil?
      type_mappings = type_mappings[_index]['mappings']

      @types.all? do |type|
        next false if type_mappings[type].nil?

        diff = Elastic::Commands::CompareMappings.for(
          current: type_mappings[type],
          user: @mapping
        )
        diff.empty?
      end
    end

    def setup_index_types(_index)
      @types.each do |type|
        api.indices.put_mapping(index: _index, type: type, body: @mapping)
      end
    end

    def transfer_alias(_alias, from: nil, to: nil)
      actions = []
      actions << { remove: { index: from, alias: _alias } } if from
      actions << { add: { index: to, alias: _alias } } if to
      api.indices.update_aliases body: { actions: actions }
    end

    def copy_documents(_from, _to, _batch_size)
      api.indices.refresh index: _from

      r = api.search(
        index: _from,
        body: { sort: ['_doc'] },
        scroll: '5m',
        size: _batch_size
      )

      count = 0
      while !r['hits']['hits'].empty?
        count += r['hits']['hits'].count
        Elastic.logger.info "Copied #{count} docs"

        body = r['hits']['hits'].map { |h| { 'index' => transform_hit_to_doc(h) } }
        api.bulk(index: _to, body: body)

        r = api.scroll scroll: '5m', scroll_id: r['_scroll_id']
      end
    end

    def configure_index(_index, _settings)
      api.indices.put_settings index: _index, body: { index: _settings }
    end

    def transform_hit_to_doc(_hit)
      { '_id' => _hit['_id'], '_type' => _hit['_type'], 'data' => _hit['_source'] }
    end

    def default_batch_size
      1_000
    end

    def small_batch_size
      500
    end

    def retry_on_temporary_error(_action, retries: 3)
      return yield
    rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable,
           Elasticsearch::Transport::Transport::Errors::GatewayTimeout => exc
      raise if retries <= 0

      Elastic.logger.warn("#{exc.class} error during '#{_action}', retrying!")
      retries -= 1
      retry
    end
  end
end
