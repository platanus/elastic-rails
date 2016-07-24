module Elastic::Results
  class Metric < Base
    attr_reader :value

    def initialize(_value)
      @value = _value
    end

    def as_value
      @value
    end
  end
end
