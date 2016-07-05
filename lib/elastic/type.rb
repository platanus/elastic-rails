module Elastic
  class Type < Types::BaseType
    extend Types::FacetedType
    extend Types::NestableType

    def self.suffix
      @suffix || default_suffix
    end

    def self.suffix=(_value)
      @suffix = _value
    end

    def self.adaptor
      @adaptor ||= Elastic::Core::Adaptor.new(suffix)
    end

    def self.mapping
      @mapping ||= load_mapping
    end

    def self.import_method
      @import_method
    end

    def self.import_method=(_value)
      @import_method = _value
    end

    def self.import_transform
      @import_transform
    end

    def self.import_transform=(_value)
      @import_transform = _value
    end

    def self.references(_tree = {})
      self.import_transform = -> { includes(_tree) }
    end

    def self.reindex(_options = {})
      adaptor.drop if adaptor.exists?

      mapping.migrate
      Commands::ImportIndexDocuments.for _options.merge(
        index: self,
        transform: import_transform,
        method: import_method
      )
      ensure_full_mapping
    end

    def self.import(_collection, _options = {})
      enforce_mapping!
      Commands::ImportIndexDocuments.for _options.merge(
        index: self,
        collection: _collection,
        transform: import_transform,
        method: import_method
      )
      ensure_full_mapping
    end

    def self.query(_query)
      enforce_mapping!
      ensure_full_mapping
      # TODO
    end

    def self.clear
      enforce_mapping!
      adaptor.clear
    end

    def save
      self.class.tap do |klass|
        klass.enforce_mapping!
        klass.adaptor.index as_es_document
        klass.ensure_full_mapping
      end
    end

    private

    def self.load_mapping
      freeze_index_definition
      Elastic::Core::MappingManager.new(adaptor, definition).tap do |mapping|
        mapping.fetch
      end
    end

    def self.enforce_mapping!
      if mapping.out_of_sync?
        raise RuntimeError, 'elastic mapping out of sync, run `rake es:migrate`'
      end
    end

    def self.ensure_full_mapping
      if mapping.incomplete?
        mapping.fetch
      end
    end

    def self.default_suffix
      to_s.underscore
    end
  end
end
