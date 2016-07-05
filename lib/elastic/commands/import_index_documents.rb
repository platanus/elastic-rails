module Elastic::Commands
  class ImportIndexDocuments < Elastic::Support::Command.new(
    :index, collection: nil, transform: nil, method: nil, cache_size: 10000
  )
    def perform
      transformed_targets.each { |target| import(target) }
      flush
    end

    private

    def import(_target)
      _target.public_send(import_method_for(_target)) do |object|
        append index.new(object).as_es_document
      end
    end

    def append(_document)
      cache << _document
      flush if cache.length > cache_size
    end

    def flush
      unless cache.empty?
        index.adaptor.bulk_index(cache)
        cache.clear
      end
    end

    def cache
      @cache ||= []
    end

    def import_method_for(_target)
      return method unless method.nil?
      return :find_each if _target.respond_to? :find_each
      return :each
    end

    def targets
      return [collection] unless collection.nil?
      index.definition.targets
    end

    def transformed_targets
      Elastic::Support::Transform.new(transform).apply_to_many targets
    end
  end
end