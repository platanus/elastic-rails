module Elastic::Capabilities
  module ContextHandler
    private

    def set_context(_name, _data)
      unless @context_name.nil?
        raise ArgumentError, "#{_name} should not be called right after #{@context_name}"
      end

      @context_name = _name.to_sym
      @context_data = _data
      self
    end

    def with_context(_names, _caller)
      _names = [_names] unless _names.is_a? Array
      _names = _names.map(&:to_sym)

      if @context_name.nil?
        raise ArgumentError, "#{_caller} should be called after #{_names.join(' or ')}"
      elsif !_names.include? @context_name
        raise ArgumentError, "#{_caller} should not be called after #{@context_name}"
      end

      yield @context_data
      return self
    ensure
      @context_name = @context_data = nil
    end
  end
end
