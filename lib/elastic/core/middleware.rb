module Elastic::Core
  module Middleware
    extend self

    def register(_middleware_class)
      middlewares << _middleware_class
    end

    def wrap(_target)
      middleware_for(_target).new _target
    end

    def middleware_for(_target)
      # TODO: improve matching logic
      middleware = middlewares.reverse_each.find { |m| m.accepts?(_target) }
      middleware = DefaultMiddleware if middleware.nil?
      middleware
    end

    private

    def middlewares
      @middlewares ||= []
    end
  end
end
