module Elastic
  module Indexable
    def self.included(_base)
      _base.extend ClassMethods
    end

    module ClassMethods
      def index_class
        @index_class = (to_s + 'Index').constantize
      end

      def elastic_mode
        @elastic_mode || :index
      end

      def elastic_mode=(_value)
        @elastic_mode = _value
      end

      def find_each_for_elastic(_options = {}, &_block)
        self.each &_block
      end

      def preload_by_elastic_ids(_ids)
        raise NotImplementedError, "Indexable classes using elastic_mode = :index \
          should implement 'preload_by_elastic_ids'"
      end

      def build_from_elastic_data(_data)
        raise NotImplementedError, "Indexable classes using elastic_mode = :storage \
          should implement 'build_from_elastic_data'"
      end

      def elastic_field_options_for(_field)
        nil
      end
    end

    def index_now
      self.class.index_class.store self
    end

    def index_later
      index_now
    end
  end
end



