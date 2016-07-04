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
        mappings = types.map { |t| mappings[t] }.reject(&:nil?)
        @index = merge_mappings_into_index mappings
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        # ignore not-found errors when fetching mappings
        @index = nil
      end

      @status = compute_status
      return self
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

    private

    def types
      @definition.targets.map(&:to_s)
    end

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
      flatten(definition.as_es_mapping).all? do |field, properties|
        @index[field] == properties
      end
    end

    def flatten(_raw, _prefix = '')
      _raw['properties'].map do |name, raw_field|
        if raw_field['type'] == 'nested'
          childs = flatten(raw_field, name + '.')
          raw_field.delete 'properties'
          childs << [_prefix + name, raw_field]
        else
          [[_prefix + name, raw_field]]
        end
      end.flatten(1)
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
      end
    end
  end
end
