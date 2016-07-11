module Elastic::Railties
  module TypeExtensions
    def self.included(_klass)
      _klass.extend ClassMethods
    end

    module ClassMethods
      def references(*_includes)
        definition.custom_options[:ar_import_includes] = _includes
      end
    end
  end
end
