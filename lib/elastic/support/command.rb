module Elastic::Support
  module Command
    def self.new(*_attributes)
      attr_names = []
      attr_defaults = {}

      _attributes.each do |att|
        if att.is_a? Hash
          attr_defaults.merge! att
          attr_names += att.keys
        else
          attr_names << att
        end
      end

      Struct.new(*attr_names) do
        def self.for(kwargs = {})
          new(kwargs).perform
        end

        def perform
        end

        define_method(:initialize) do |kwargs = {}|
          kwargs = attr_defaults.merge kwargs
          attr_values = attr_names.map { |a| kwargs[a] }
          super(*attr_values)
        end

        define_method(:perform) {}
      end
    end
  end
end
