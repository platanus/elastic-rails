module Elastic::Core
  class BaseMiddleware
    attr_reader :target

    def initialize(_target)
      @target = _target
    end

    def type_name
      @target.to_s
    end

    def mode
      not_supported :mode
    end

    def field_options_for(_field, _options)
      not_supported :field_options_for
    end

    def collect_all(_options, &_block)
      not_supported :collect_all
    end

    def collect_from(_collection, _options, &_block)
      not_supported :collect_from
    end

    def find_by_ids(_ids, _options)
      not_supported :find_by_ids
    end

    def build_from_data(_data, _options)
      not_supported :build_from_data
    end

    private

    def not_supported(_feature)
      raise NotImplementedError, "#{self.class} does not support '#{_feature}'"
    end
  end
end
