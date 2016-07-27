module Elastic::Results
  class ResultGroup < Base
    attr_reader :keys, :data

    def initialize(_keys, _data)
      @keys = _keys.freeze
      @data = _data
    end

    def as_value
      @data.as_value
    end

    def traverse(&_block)
      super
      @data.traverse(&_block)
    end
  end
end
