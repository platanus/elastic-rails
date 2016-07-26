module Elastic::Railties
  module Utils
    def reindex(_index = nil)
      Rails.logger.info "Reindexing indices" if _index.nil?
      indices(_index).each do |index|
        Rails.logger.info "Reindexing index #{index.suffix}"
        handle_errors { index.reindex }
      end
    end

    def migrate(_index = nil)
      Rails.logger.info "Migrating indices" if _index.nil?
      indices(_index).each do |index|
        Rails.logger.info "Migrating index #{index.suffix}"
        handle_errors { index.mapping.migrate }
      end
    end

    def stats(_index = nil)
      Rails.logger.info "Indices stats" if _index.nil?
      indices(_index).each do |index|
        Rails.logger.info "Stats for #{index.suffix}:"
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
      Rails.root.join(Elastic::Configuration.indices_path)
    end

    def handle_errors
      yield
    rescue => exc
      Rails.logger.error exc.message
      Rails.logger.error exc.backtrace.join("\n")
    end
  end
end
