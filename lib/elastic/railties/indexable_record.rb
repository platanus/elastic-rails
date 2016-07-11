module Elastic::Railties
  module IndexableRecord
    def self.included(_base)
      _base.include Elastic::Indexable
      _base.extend ClassMethods
    end

    module ClassMethods
      def elastic_mode
        :index # storage mode not supported for AR
      end

      def collect_for_elastic(_definition, _from = nil, &_block)
        # Check that collection matches type?
        ARHelpers.find_each_with_options(
          _from || self,
          includes: _definition.custom_options[:ar_import_includes],
          scope: _definition.custom_options[:ar_import_scope],
          &_block
        )
      end

      def preload_by_elastic_ids(_definition, _ids)
        where(id: _ids)
      end

      def elastic_field_options_for(_definition, _field)
        if Rails.version.to_f >= 4.2
          ARHelpers.infer_ar5_field_options(self, _field)
        else
          ARHelpers.infer_ar4_field_options(self, _field)
        end
      end

      def index(_options)
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
    end
  end
end
