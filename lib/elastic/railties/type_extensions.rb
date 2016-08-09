module Elastic::Railties
  module TypeExtensions
    def self.included(_klass)
      _klass.extend ClassMethods
    end

    module ClassMethods
      def references(*_includes)
        # TODO: check target allows options
        pre_definition.middleware_options[:ar_collect_includes] = _includes
      end
    end
  end
end
