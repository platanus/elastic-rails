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
        @constantized_index_class ||= @index_class.constantize
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

    def index_now
      self.class.constantized_index_class.store self
    end

    def index_later
      # TODO: ActiveJob support
      index_now
    end
  end
end
