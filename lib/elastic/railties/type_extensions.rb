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

      def index_later(_object)
        wrapped = new(_object)

        Jobs::IndexingJob
          .set(queue: Elastic.config.active_job_queue)
          .perform_later(to_s, wrapped.as_elastic_document.as_json)
      end

      def delete_later(_object)
        wrapped = new(_object)

        Jobs::DeletingJob
          .set(queue: Elastic.config.active_job_queue)
          .perform_later(to_s, wrapped.as_elastic_document(only_meta: true).as_json)
      end
    end
  end
end
