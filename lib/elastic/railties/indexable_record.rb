module Elastic::Railties
  module IndexableRecord
    def self.included(_base)
      _base.extend ClassMethods
    end

    module ClassMethods
      def index_class
        @index_class ||= to_s + 'Index'
      end

      def index_class=(_class)
        @constantized_index_class = nil
        @index_class = _class
      end

      def constantized_index_class
        @constantized_index_class ||= index_class.constantize
      end

      def index(on: nil, unindex: true, delayed: false)
        raise NotImplementedError, 'delayed indexing not implemented' if delayed

        if on == :create
          index_on_create
        elsif on == :save
          index_on_save
        else
          raise ArgumentError, 'must provide an indexing target when calling index \
(ie: `index on: :save`)'
        end

        unindex_on_destroy if unindex
      end

      def index_on_create(_options = {})
        after_create(_options) { index_now }
      end

      def index_on_save(_options = {})
        after_save(_options) { index_now }
      end

      def unindex_on_destroy(_options = {})
        before_destroy(_options) { unindex_now }
      end
    end

    def index_now
      self.class.constantized_index_class.index self
    end

    def unindex_now
      self.class.constantized_index_class.delete self
    end
  end
end
