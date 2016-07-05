module Elastic::Core
  class Adaptor
    def initialize(_suffix)
      @suffix = _suffix
    end

    def index_name
      @index_name ||= "#{Elastic::Configuration.index_name}_#{@suffix}"
    end

    def remap(_type, _mapping)
      # TODO
    end

    def exists?
      api_client.indices.exists? build_options
    end

    def ensure_index
      create unless exists?
      self
    end

    def create
      api_client.indices.create build_options
      api_client.cluster.health wait_for_status: 'yellow'
      self
    end

    def drop
      api_client.indices.delete build_options
      self
    end

    def exists_type?(_type)
      api_client.indices.exists_type build_options(type: _type)
    end

    def exists_mapping?(_type)
      !api_client.indices.get_mapping(build_options(type: _type)).empty?
    end

    def get_mappings(type: nil)
      mappings = api_client.indices.get_mapping build_options(type: type)
      mappings[index_name]['mappings']
    end

    def set_mapping(_type, _mapping)
      api_client.indices.put_mapping build_options(
        type: _type,
        update_all_types: true,
        body: _mapping
      )
      self
    end

    def index(_document)
      api_client.index build_options(
        id: _document['_id'],
        type: _document['_type'],
        body: _document['data']
      )
      self
    end

    def bulk_index(_documents)
      body = _documents.map do |doc|
        { 'index' => doc.merge('_index' => index_name) }
      end

      api_client.bulk body: body
      self
    end

    def refresh
      api_client.indices.refresh build_options
      self
    end

    def find(_id, type: '_all')
      api_client.get build_options(type: type, id: _id)
    end

    def count(type: nil, query: nil)
      api_client.count(build_options(type: type, body: query))['count']
    end

    def query(type: nil, query: nil)
      api_client.search build_options(type: type, body: query)
    end

    def clear(_query = nil)
      if _query.nil?
        return unless exists?
        api_client.delete_by_query build_options(body: { "match_all" => {} })
      else
        api_client.delete_by_query build_options(body: _query)
      end
    end

    private

    def api_client
      Elastic::Configuration.api_client
    end

    def build_options(_options = {})
      { index: index_name }.merge! _options
    end
  end
end
