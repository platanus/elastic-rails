module Elastic
  class ValueTransform
    attr_reader :context, :transform

    def initialize(_context, _transform)
      @context = _context
      @transform = _transform
    end

    def apply(_value)
      return _value.public_send @transform if @transform.is_a? String
      _value.instance_exec(&@transform)
    end
  end
end
