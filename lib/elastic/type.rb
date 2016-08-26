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

    def self.connector
      @connector ||= load_connector
    end

    def self.es_index_name
      connector.index_name
    end

    def self.reindex(verbose: true, batch_size: nil)
      drop
      connector.migrate
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
      batch_size = batch_size || import_batch_size

      Commands::ImportIndexDocuments.for(
        index: self,
        collection: _collection,
        batch_size: batch_size
      )

      self
    end

    def self.index(_object)
      new(_object).save
    end

    def self.query
      Query.new self
    end

    def self.drop
      connector.drop
      self
    end

    def self.refresh
      connector.refresh
      self
    end

    def save
      self.class.tap do |klass|
        klass.connector.index as_es_document
      end
    end

    def self.load_connector
      connector = Elastic::Core::Connector.new(
        suffix,
        definition.types,
        definition.as_es_mapping
      )

      if Configuration.whiny_indices && connector.status != :ready
        raise 'elastic index out of sync, run `rake es:migrate`'
      end

      connector
    end

    private_class_method :load_connector

    def self.default_suffix
      to_s.underscore
    end

    private_class_method :default_suffix
  end
end
