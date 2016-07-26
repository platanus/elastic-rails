module Elastic::Railties
  module QueryExtensions
    def includes(*_includes)
      with_clone do |config|
        config.middleware_options[:ar_includes] = _includes
      end
    end
  end
end
