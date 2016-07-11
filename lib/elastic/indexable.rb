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

      def collect_for_elastic(_definition, _from = nil, &_block)
        _from = self unless _from
        if _from.respond_to? :find_each_for_elastic
          _from.find_each_for_elastic &_block
        elsif _from.respond_to? :each
          _from.each &_block
        end
      end

      def preload_by_elastic_ids(_definition, _ids)
        raise NotImplementedError, "Indexable classes using elastic_mode = :index \
should implement 'preload_by_elastic_ids'"
      end

      def build_from_elastic_data(_definition, _data)
        raise NotImplementedError, "Indexable classes using elastic_mode = :storage \
should implement 'build_from_elastic_data'"
      end

      def elastic_field_options_for(_definition, _field)
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
