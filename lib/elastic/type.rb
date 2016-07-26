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

    def self.adaptor
      @adaptor ||= Elastic::Core::Adaptor.new(suffix)
    end

    def self.mapping
      @mapping ||= load_mapping
    end

    def self.reindex
      drop
      mapping.migrate
      Commands::ImportIndexDocuments.for index: self
      ensure_full_mapping
      self
    end

    def self.import(_collection)
      enforce_mapping!
      Commands::ImportIndexDocuments.for index: self, collection: _collection
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

    private_class_method def self.load_mapping
      freeze_index_definition
      Elastic::Core::MappingManager.new(adaptor, definition).tap(&:fetch)
    end

    private_class_method def self.default_suffix
      to_s.underscore
    end
  end
end
