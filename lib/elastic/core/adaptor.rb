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

    def exists_type?(_type)
      begin
        api_client.indices.exists_type build_options(type: _type)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return false
      end
    end

    def exists_mapping?(_type)
      begin
        !api_client.indices.get_mapping(build_options(type: _type)).empty?
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return false
      end
    end

    def create
      api_client.indices.create build_options
      api_client.cluster.health wait_for_status: 'yellow'
    end

    def ensure_index
      create unless exists?
    end

    def get_mappings
      mappings = api_client.indices.get_mapping build_options
      mappings[index_name]['mappings']
    end

    def set_mapping(_type, _mapping)
      api_client.indices.put_mapping build_options(
        type: _type,
        update_all_types: true,
        body: _mapping
      )
    end

    def index(_document)
      api_client.index build_options(
        id: _document['_id'],
        type: _document['_type'],
        body: _document['data']
      )
    end

    def find(_id, type: '_all')
      begin
        api_client.get build_options(type: type, id: _id)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return nil
      end
    end

    def query(_query, type: nil)
      api_client.search build_options(body: _query, type: type)
    end

    def count(_query, type: nil)
      r = api_client.count build_options(body: _query, type: type)
      r["count"]
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
