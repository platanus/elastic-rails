module Elastic
  class Type < Types::BaseType
    extend Types::FacetedType
    extend Types::NestableType

    class << self
      extend Forwardable

      def_delegators :query, :must, :should, :segment, :stats, :maximum, :minimum, :sum, :average,
        :coord_similarity, :limit, :offset, :pluck, :ids, :total
    end

    def self.suffix
      @suffix || default_suffix
    end

    def self.suffix=(_value)
      @suffix = _value
    end

    def self.import_batch_size
      @import_batch_size || Configuration.import_batch_size
    end

    def self.import_batch_size=(_value)
      @import_batch_size = _value
    end

    def self.adaptor
      @adaptor ||= Elastic::Core::Adaptor.new(suffix)
    end

    def self.mapping
      @mapping ||= load_mapping
    end

    def self.reindex(verbose: true, batch_size: nil)
      drop
      mapping.migrate
      batch_size = batch_size || import_batch_size

      Commands::ImportIndexDocuments.for(
        index: self,
        verbose: verbose,
        batch_size: batch_size
      )

      ensure_full_mapping
      self
    end

    def self.import(_collection, batch_size: nil)
      enforce_mapping!
      batch_size = batch_size || import_batch_size

      Commands::ImportIndexDocuments.for(
        index: self,
        collection: _collection,
        batch_size: batch_size
      )

      ensure_full_mapping
      self
    end

    def self.index(_object)
      new(_object).save
    end

    def self.query
      enforce_mapping!
      ensure_full_mapping
      Query.new self
    end

    def self.drop
      adaptor.drop if adaptor.exists?
      self
    end

    def self.refresh
      adaptor.refresh
      self
    end

    def self.enforce_mapping!
      if mapping.out_of_sync?
        raise 'elastic mapping out of sync, run `rake es:migrate`'
      end
    end

    def self.ensure_full_mapping
      if mapping.incomplete?
        mapping.fetch
      end
    end

    def save
      self.class.tap do |klass|
        klass.enforce_mapping!
        klass.adaptor.index as_es_document
        klass.ensure_full_mapping
      end
    end

    def self.load_mapping
      Elastic::Core::MappingManager.new(adaptor, definition).tap(&:fetch)
    end

    private_class_method :load_mapping

    def self.default_suffix
      to_s.underscore
    end

    private_class_method :default_suffix
  end
end
