module Elastic::Core
  class Result
    include Enumerable

    attr_reader :index, :options

    def initialize(_index, _es_query, _options)
      @index = _index
      @es_query = _es_query
      @options = _options
    end

    def ids(_type = nil)
      result = cached? ? raw_result : execute_query([])

      hits = result['hits']['hits']
      hits = hits.select { |h| h['_type'] == _type } if _type
      hits.map { |h| h['_id'].to_i }
    end

    def pluck(_field)
      _field = _field.to_s
      # TODO: support nested fields
      result = execute_query([_field])
      result['hits']['hits'].map do |hit|
        formatter.format(hit['_source'])[_field]
      end
    end

    def count
      if cached?
        raw_result['hits']['total']
      else
        count_by_query
      end
    end

    def [](_idx)
      all_hits[_idx].try(:ref)
    end

    def each(*_args)
      all_hits.map(&:ref).each *_args
    end

    def each_hit(*_args)
      all_hits.each(*_args)
    end

    def each_with_score(*_args)
      all_hits.map { |h| [h.ref, h.score] }.each(*_args)
    end

    def find_each
      # TODO: use scroll
    end

    def as_es_query
      @es_query
    end

    private

    def all_hits
      @all_hits ||= preload(raw_result['hits']['hits']).to_a
    end

    def cached?
      !@raw_result.nil?
    end

    def raw_result
      @raw_result ||= execute_query(default_fields)
    end

    def execute_query(_fields)
      @index.adaptor.query(
        type: @index.definition.types,
        query: query_for_fields(_fields)
      )
    end

    def count_by_query
      @index.adaptor.count(
        type: @index.definition.types,
        query: query_for_count
      )
    end

    def query_for_count
      { 'query' => @es_query['query'] }
    end

    def query_for_fields(_fields)
      return @es_query if _fields.nil?
      @es_query.merge('_source' => _fields)
    end

    def default_fields
      index_mode? ? false : nil
    end

    def preload(_raw_hits)
      _hits = _raw_hits.map { |h| Hit.new(h) }
      groups = _hits.group_by(&:type)
      groups.each { |t, h| preload_hits(t, h) }
      _hits
    end

    def preload_hits(_type_name, _hits)
      target = resolve_target(_type_name)
      raise "Unexpected type name #{_type_name}" if target.nil?

      if index_mode?
        ids = _hits.map(&:id)
        objects = target.find_by_ids(ids, @options)
        objects.each_with_index { |o, i| _hits[i].ref = o }
      else
        _hits.each do |hit|
          hit.ref = target.build_from_data(
            formatter.format(hit.source),
            @options
          )
        end
      end
    end

    def index_mode?
      @index.definition.main_target.mode == :index
    end

    def resolve_target(_type_name)
      @index.definition.targets.find { |t| t.type_name == _type_name }
    end

    def formatter
      @formatter ||= SourceFormatter.new(@index.mapping)
    end
  end
end
