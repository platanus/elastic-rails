module Elastic::Railties
  module IndexableRecord
    def self.included(_base)
      _base.include Elastic::Indexable
      _base.extend ClassMethods
    end

    module ClassMethods
      def find_each_for_elastic(_options = {}, &_block)
        # TODO:
      end

      def elastic_mode
        :index # storage mode not supported for AR
      end

      def preload_by_elastic_ids(_ids)
        self.where(id: _ids)
      end

      def elastic_field_options_for(_field)
        if Rails.version.to_f >= 4.2
          ARHelpers.infer_ar5_field_options(self, _field)
        else
          ARHelpers.infer_ar4_field_options(self, _field)
        end
      end

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

      def index_all
        index_class.clear

        scope = self
        scope = self.includes(@index_depends) if @index_depends
        scope.find_each { |r| index_class.store(r) } # TODO: index_many
      end
    end
  end
end
