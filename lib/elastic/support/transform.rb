module Elastic::Support
  class Transform
    def initialize(_transform)
      @transform = _transform
    end

    def apply(_value)
      case @transform
      when Symbol
        _value.public_send @transform
      when String
        _value.instance_eval(@transform)
      when Proc
        _value.instance_exec(&@transform)
      when nil
        _value
      else
        raise ArgumentError, "invalid transformation type #{@transform.class}"
      end
    end

    def apply_to_many(_values)
      case @transform
      when Symbol
        _values.map(&@transform)
      when String
        _values.map { |v| v.instance_eval(@transform) }
      when Proc
        _values.map { |v| v.instance_exec(&@transform) }
      when nil
        _values
      else
        raise ArgumentError, "invalid transformation type #{@transform.class}"
      end
    end
  end
end
