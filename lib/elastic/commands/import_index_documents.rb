module Elastic::Commands
  class ImportIndexDocuments < Elastic::Support::Command.new(
    :index, collection: nil, cache_size: 10000
  )
    def perform
      if collection.present?
        import_collection
      else
        targets.each { |target| import_target(target) }
      end
      flush
    end

    private

    def import_collection
      main_target.collect_for(collection, middleware_options) { |obj| queue obj }
    end

    def import_target(_target)
      _target.collect_all(middleware_options) { |obj| queue obj }
    end

    def cache
      @cache ||= []
    end

    def queue(_object)
      cache << render_for_es(_object)
      flush if cache.length > cache_size
    end

    def flush
      unless cache.empty?
        index.adaptor.bulk_index(cache)
        cache.clear
      end
    end

    def render_for_es(_object)
      index.new(_object).as_es_document
    end

    def main_target
      index.definition.main_target
    end

    def targets
      index.definition.targets
    end

    def middleware_options
      index.definition.middleware_options
    end
  end
end
