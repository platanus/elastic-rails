module Elastic::Railties
  module ConfigurationExtensions
    def self.included(_klass)
      _klass::DEFAULTS[:active_job_queue] = :default
      _klass::DEFAULTS[:indices_path] = 'app/indices'
    end

    attr_accessor :active_job_queue, :indices_path
  end
end
