module Elastic::Commands
  class CompareMappings < Elastic::Support::Command.new(:current, :user)
    def perform
      user_properties.select do |field, property|
        !compare_field_properties(current_properties[field], property)
      end.map { |f| f[0] }
    end

    private

    def current_properties
      @current_properties ||= Hash[flatten(current)]
    end

    def user_properties
      @user_properties ||= Hash[flatten(user)]
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

    def compare_field_properties(_current, _user)
      return false if _current.nil?

      case _current['type']
      when 'date'
        return _current == { 'format' => 'dateOptionalTime' }.merge(_user)
      else
        return _current == _user
      end
    end
  end
end
