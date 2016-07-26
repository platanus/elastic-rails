module Elastic::Core
  class MappingManager
    attr_reader :adaptor, :definition

    def initialize(_adaptor, _definition)
      @adaptor = _adaptor
      @definition = _definition
      @status = :pending
    end

    def out_of_sync?
      @status == :out_of_sync
    end

    def incomplete?
      @status == :incomplete
    end

    def fetch
      begin
        mappings = @adaptor.get_mappings
        mappings = @definition.types.map { |t| mappings[t] }.reject(&:nil?)
        @index = merge_mappings_into_index mappings
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        # ignore not-found errors when fetching mappings
        @index = nil
      end

      @status = compute_status
      self
    end

    def unmapped_fields
      @definition.expanded_field_names.reject { |f| has_field? f }
    end

    def has_field?(_name)
      @index.key? _name
    end

    def get_field_options(_name)
      @index[_name] || {}
    end

    def migrate
      # TODO: make this a command
      @adaptor.create unless @adaptor.exists?
      begin
        @definition.types.each { |t| @adaptor.set_mapping(t, user_mapping) }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        # TODO: https://www.elastic.co/guide/en/elasticsearch/guide/current/reindex.html
      end
      fetch
    end

    private

    def compute_status
      if !synchronized?
        :out_of_sync
      elsif unmapped_fields.count > 0
        :incomplete
      else
        :ready
      end
    end

    def synchronized?
      return false if @index.nil?
      flatten(user_mapping).all? do |field, properties|
        @index[field] == properties
      end
    end

    def user_mapping
      @user_mapping ||= definition.as_es_mapping
    end

    def flatten(_raw, _prefix = '')
      _raw['properties'].flat_map do |name, raw_field|
        if raw_field['type'] == 'nested'
          childs = flatten(raw_field, name + '.')
          childs << [
            _prefix + name,
            raw_field.slice(*(raw_field.keys - ['properties']))
          ]
        else
          [[_prefix + name, raw_field.dup]]
        end
      end
    end

    def merge_mappings_into_index(_mappings)
      {}.tap do |result|
        _mappings.each do |mapping|
          index = flatten(mapping)
          index.each do |field, properties|
            if result.key? field
              result[field].merge! properties
            else
              result[field] = properties
            end
          end
        end
        result.each_value(&:freeze)
      end
    end
  end
end
