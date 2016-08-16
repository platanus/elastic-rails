module Elastic::Railties
  module ConfigurationExtensions
    def self.included(_klass)
      _klass.extend ClassMethods
    end

    module ClassMethods
      def active_job_queue
        config[:active_job_queue] || :default
      end
    end
  end
end
