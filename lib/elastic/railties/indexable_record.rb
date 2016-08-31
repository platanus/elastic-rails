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

      def index(on: nil, unindex: true, delayed: true)
        index_m, unindex_m = delayed ? [:index_later, :unindex_later] : [:index_now, :unindex_now]

        if on == :create
          after_create { public_send(index_m) }
        elsif on == :save
          after_save { public_send(index_m) }
        else
          raise ArgumentError, 'must provide an indexing target when calling index \
(ie: `index on: :save`)'
        end

        before_destroy { public_send(unindex_m) } if unindex
      end
    end

    def index_later
      self.class.constantized_index_class.index_later self
    end

    def unindex_later
      self.class.constantized_index_class.delete_later self
    end

    def index_now
      self.class.constantized_index_class.index self
    end

    def unindex_now
      self.class.constantized_index_class.delete self
    end
  end
end
