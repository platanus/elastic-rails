module Elastic::Core
  class Connector
    def initialize(_name, _mapping, settling_time: 10.seconds)
      @name = _name
      @mapping = _mapping
      @settling_time = settling_time
    end

    def index_name
      @index_name ||= "#{Elastic.config.index}_#{@name}"
    end

    def status
      return :ready if Elastic.config.disable_indexing

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
          setup_index_mapping resolve_actual_index_name
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest
          return false
        end
      end

      true
    end

    def migrate(batch_size: nil)
      unless remap
        rollover do |new_index|
          copy_to new_index, batch_size: batch_size
        end
      end
      nil
    end

    def index(_document)
      return if Elastic.config.disable_indexing

      # TODO: validate document type
      operations = write_indices.map do |write_index|
        { 'index' => _document.merge('_index' => write_index) }
      end

      api.bulk(body: operations)
    end

    def bulk_index(_documents)
      return if Elastic.config.disable_indexing

      # TODO: validate documents type
      body = _documents.map { |doc| { 'index' => doc } }

      write_indices.each do |write_index|
        retry_on_temporary_error('bulk indexing') do
          api.bulk(index: write_index, body: body)
        end
      end
    end

    def delete(_document)
      raise ArgumentError, 'document must provide an id' unless _document['_id']

      return if Elastic.config.disable_indexing

      write_index, rolling_index = write_indices

      operations = [{
        'delete' => _document.merge('_index' => write_index)
      }]

      if rolling_index
        operations << {
          'delete' => _document.merge('_index' => rolling_index)
        }
      end

      api.bulk(body: operations)
    end

    def refresh
      api.indices.refresh index: index_name
    end

    def find(_id)
      api.get(index: index_name, id: _id)
    end

    def count(query: nil)
      api.count(index: index_name, body: query)['count']
    end

    def query(query: nil)
      api.search(index: index_name, body: query)
    end

    def rollover(&_block) # rubocop:disable Metrics/MethodLength
      actual_index, rolling_index = resolve_write_indices

      unless rolling_index.nil?
        raise Elastic::RolloverError, 'rollover process already in progress'
      end

      new_index = create_index_w_mapping

      begin
        transfer_alias(write_index_alias, to: new_index)
        wait_for_index_to_stabilize
        perform_optimized_write_on(new_index, &_block)
        transfer_alias(index_name, from: actual_index, to: new_index)
        transfer_alias(write_index_alias, from: actual_index)
        wait_for_index_to_stabilize
        api.indices.delete index: actual_index
      rescue StandardError
        api.indices.delete index: new_index
        raise
      end
    end

    def copy_to(_to, batch_size: nil) # rubocop:disable Metrics/AbcSize
      api.indices.refresh index: index_name

      r = api.search(
        index: index_name,
        body: { sort: ['_doc'] },
        scroll: '5m',
        size: batch_size || default_batch_size
      )

      count = 0
      while !r['hits']['hits'].empty?
        count += r['hits']['hits'].count
        Elastic.logger.info "Copied #{count} docs"

        body = r['hits']['hits'].map { |h| transform_hit_to_create(h) }
        api.bulk(index: _to, body: body)

        r = api.scroll scroll: '5m', scroll_id: r['_scroll_id']
      end
    end

    def remove_orphaned_indices
      _, rolling_index = resolve_write_indices

      unless rolling_index.nil?
        Elastic.logger.info "Removing orphan index #{rolling_index}"
        api.indices.delete index: rolling_index
      end
    end

    private

    def wait_for_index_to_stabilize
      return if @settling_time.zero?

      Elastic.logger.info "Waiting #{@settling_time * 1.2}s for write indices to catch up ..."
      sleep(@settling_time * 1.2)
    end

    def api
      Elastic.config.api_client
    end

    def write_indices
      Thread.current[write_index_thread_override] || resolve_write_indices
    end

    def perform_optimized_write_on(_index)
      old_indices = Thread.current[write_index_thread_override]
      Thread.current[write_index_thread_override] = [_index]
      configure_index(_index, refresh_interval: -1)
      yield _index
    ensure
      configure_index(_index, refresh_interval: '1s')
      Thread.current[write_index_thread_override] = old_indices
    end

    def write_index_thread_override
      "_elastic_#{index_name}_write_index"
    end

    def write_index_alias
      @write_index_alias ||= "#{index_name}.w"
    end

    def resolve_write_indices
      @write_indices = nil if Elastic.config.disable_index_name_caching || write_indices_expired?
      @write_indices ||= begin
        result = api.indices.get_alias(name: write_index_alias)
        @write_indices_expiration = @settling_time.from_now
        result.keys.sort # lower timestamp first (actual)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        raise Elastic::MissingIndexError, 'index does not exist, call migrate first'
      end
    end

    def write_indices_expired?
      @write_indices_expiration && @write_indices_expiration < Time.current
    end

    def resolve_actual_index_name
      result = api.indices.get_alias(name: index_name)
      result.keys.first
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def create_index_w_mapping
      new_name = "#{index_name}:#{Time.now.to_i}"
      api.indices.create index: new_name
      api.cluster.health wait_for_status: 'yellow'
      setup_index_mapping new_name
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
      return false if type_mappings[_index]['mappings'].empty?

      diff = Elastic::Commands::CompareMappings.for(
        current: type_mappings[_index]['mappings'],
        user: @mapping
      )

      diff.empty?
    end

    def setup_index_mapping(_index)
      api.indices.put_mapping(index: _index, body: @mapping)
    end

    def transfer_alias(_alias, from: nil, to: nil)
      actions = []
      actions << { remove: { index: from, alias: _alias } } if from
      actions << { add: { index: to, alias: _alias } } if to
      api.indices.update_aliases body: { actions: actions }
    end

    def configure_index(_index, _settings)
      api.indices.put_settings index: _index, body: { index: _settings }
    end

    def transform_hit_to_create(_hit)
      {
        'create' => {
          '_id' => _hit['_id'],
          'data' => _hit['_source']
        }
      }
    end

    def default_batch_size
      1_000
    end

    def retry_on_temporary_error(_action, retries: 3)
      yield
    rescue Elasticsearch::Transport::Transport::Errors::ServiceUnavailable,
           Elasticsearch::Transport::Transport::Errors::GatewayTimeout => exc
      raise if retries <= 0

      Elastic.logger.warn("#{exc.class} error during '#{_action}', retrying!")
      retries -= 1
      retry
    end
  end
end
