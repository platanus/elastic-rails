module Elastic
  class Type < Types::BaseType
    extend Types::FacetedType
    extend Types::NestableType

    class << self
      extend Forwardable

      def_delegators :query, :must, :should, :segment, :stats, :maximum, :minimum, :sum, :average,
        :coord_similarity, :limit, :offset, :pluck, :ids, :total
    end

    def self.default_suffix
      to_s.underscore
    end

    def self.suffix
      @suffix || default_suffix
    end

    def self.suffix=(_value)
      @suffix = _value
    end

    def self.import_batch_size
      @import_batch_size || Elastic.config.import_batch_size
    end

    def self.import_batch_size=(_value)
      @import_batch_size = _value
    end

    def self.connector
      @connector ||= begin
        Elastic::Core::Connector.new(
          suffix,
          definition.types,
          definition.as_es_mapping
        ).tap do |conn|
          if Elastic.config.whiny_indices && conn.status != :ready
            raise 'elastic index out of sync, try migrating'
          end
        end
      end
    end

    def self.index_name
      connector.index_name
    end

    def self.migrate
      connector.migrate(batch_size: import_batch_size)
      self
    end

    def self.reindex(verbose: true)
      connector.rollover do
        Commands::ImportIndexDocuments.for(
          index: self,
          verbose: verbose,
          batch_size: import_batch_size
        )
      end

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
  end
end
