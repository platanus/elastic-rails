module Elastic
  class Index
    attr_reader :api_client, :index_name

    def initialize(_api_client, _index_name)
      @api_client = _api_client
      @index_name = _index_name
      # TODO: multiple index mode (one per type)
    end

    def truncate
      api_client.indices.delete index: index_name # TODO: add +'*' in multi index mode
      clear_index_cache
    end

    def refresh
      ensure_index index_name
      api_client.indices.refresh index: index_name # TODO: add +'*' in multi index mode
    end

    def index(_type, _data, mapping: nil)
      ensure_type(_type)
      ensure_mapping(_type, mapping) unless mapping.nil?

      options = {
        index: index_name,
        type: _type,
        body: _data
      }

      options[:id] = _data[:id] if _data.key? :id

      api_client.index(options)
    end

    def exists?(_type)
      api_client.indices.exists_type build_options(_type)
    end

    def clear(_type, _query = nil)
      if _query.nil?
        return unless exists? _type
        api_client.indices.delete_mapping build_options(_type)
        clear_type_cache(_type)
      else
        ensure_type(_type)
        api_client.delete_by_query build_options(_type, q: _query)
      end
    end

    def query(_type, _query)
      ensure_type(_type)
      api_client.search build_options(_type, body: _query)
    end

    def count(_type, _query = nil)
      ensure_type(_type)
      r = api_client.count build_options(_type, body: _query)
      r["count"]
    end

    private

    def self.clear_cache
      @@index_cache = nil
      @@mapping_cache = nil
    end

    def index_cache
      @@index_cache ||= {}
    end

    def mapping_cache
      @@mapping_cache ||= {}
    end

    def build_options(_type, _options = {})
      # TODO: in multiple index mode use { index: index_name + _type }
      { index: index_name, type: _type }.merge! _options
    end

    def clear_index_cache
      clear_cache
    end

    def clear_type_cache(_type)
      mapping_cache[type_key(_type)]
    end

    def ensure_index(_name)
      return if index_cache[_name]
      return if api_client.indices.exists? index: _name
      api_client.indices.create index: _name
      api_client.cluster.health wait_for_status: 'yellow'
    end

    def ensure_type(_type)
      ensure_index(index_name)
    end

    def ensure_mapping(_type, _mapping)
      return if mapping_cache[type_key(_type)] == _mapping
      api_client.indices.put_mapping index: index_name, type: _type, body: _mapping
      mapping_cache[type_key(_type)] = _mapping
    end

    def type_key(_type)
      index_name + '/' + _type
    end

    clear_cache
  end
end
