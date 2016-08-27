module Elastic::Railties
  module Utils
    def reindex(_index = nil)
      logger.info "Reindexing all indices" if _index.nil?
      indices(_index).each do |index|
        logger.info "Reindexing index #{index.suffix}"
        handle_errors { index.reindex }
      end
    end

    def remap(_index = nil)
      logger.info "Remapping all indices" if _index.nil?
      indices(_index).each do |index|
        logger.info "Remapping index #{index.suffix}"
        handle_errors do
          unless index.connector.remap
            logger.info 'Mapping couldnt be changed, make sure you call migrate'
          end
        end
      end
    end

    def migrate(_index = nil)
      logger.info "Migrating all indices" if _index.nil?
      indices(_index).each do |index|
        logger.info "Migrating index #{index.suffix}"
        handle_errors { index.migrate }
      end
    end

    def drop(_index = nil)
      logger.info "Dropping all indices" if _index.nil?
      indices(_index).each &:drop
    end

    def stats(_index = nil)
      logger.info "Indices stats" if _index.nil?
      indices(_index).each do |index|
        logger.info "Stats for #{index.suffix}:"
        # TODO.
      end
    end

    private

    def indices(_index = nil)
      Dir.glob(indices_paths.join('**/*.rb')).map do |path|
        path = Pathname.new path
        path = path.relative_path_from indices_paths
        path = path.dirname.join(path.basename(path.extname)).to_s
        next nil if _index && (path != _index && path.camelize != _index)

        klass = path.camelize.constantize
        next nil unless klass < Elastic::Type
        klass
      end.reject(&:nil?)
    end

    def indices_paths
      Rails.root.join(Elastic.config.indices_path)
    end

    def handle_errors
      yield
    rescue => exc
      logger.error exc.message
      logger.error exc.backtrace.join("\n")
    end

    def logger
      Elastic.logger
    end
  end
end
