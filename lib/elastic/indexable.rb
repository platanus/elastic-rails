module Elastic
  module Indexable
    def self.included(_base)
      _base.extend ClassMethods
    end

    module ClassMethods
      def index_class
        @index_class = (to_s + 'Index').constantize
      end

      def query
        Elastic::Query.new index_class
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
