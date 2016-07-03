module Elastic
  class MappingManager
    def initialize(_adaptor, _types)
      @adaptor = _adaptor
      @types = _types
    end

    def fetch
      begin
        mappings = @adaptor.get_mappings
        mappings = @types.map { |t| mappings[t] }.reject(&:nil?)
        @index = merge_mappings_into_index mappings
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        # ignore not-found errors when fetching mappings
        @index = nil
      end
      # TODO: store merged mapping lock file for production env
      return
    end

    def synchronized?(_mapping)
      return false if @index.nil?
      flatten(_mapping).all? do |field, properties|
        @index[field] == properties
      end
    end

    def has_field?(_name)
      @index.key? _name
    end

    def get_field(_name)
      @index[_name] || {}
    end

    alias :[] :get_field

    private

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

# {"properties"=>
#         {"current_job_duration"=>{"type"=>"long"},
#          "experiences"=>
#           {"type"=>"nested",
#            "properties"=>
#             {"area"=>{"type"=>"long"},
#              "company"=>{"type"=>"long"},
#              "current_experience"=>{"type"=>"boolean"},
#              "industry"=>{"type"=>"long"},
#              "job_duration"=>{"type"=>"long"},
#              "position"=>{"type"=>"long"}}},
#          "job_rotation"=>{"type"=>"long"},
#          "profile_id"=>{"type"=>"long"},
#          "total_experience_time"=>{"type"=>"long"}}}}}}