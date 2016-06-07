module Elastic
  module IndexableRecord
    def self.included(_base)
      _base.include Indexable
      _base.extend ClassMethods
    end

    module ClassMethods
      def index(_options)
        index_depends(_options.delete(:depends))
        on = _options.delete(:on)

        if on == :create
          index_on_create _options
        elsif on == :save
          index_on_save _options
        end
      end

      def index_on_create(_options = {})
        after_create(_options) { index_later }
      end

      def index_on_save(_options = {})
        after_save(_options) { index_later }
      end

      def index_depends(_depends)
        @index_depends = _depends
      end

      def reindex
        index_class.clear

        scope = self
        scope = self.includes(@index_depends) if @index_depends
        scope.find_each { |r| index_class.store(r) } # TODO: index_many
      end

      def search
        # TODO: index_class.query.decorate blabla
      end
    end
  end
end
