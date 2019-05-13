module Elastic::Datatypes
  class String < Default
    def mapping_options
      options = super
      options[:type] = 'text'
      options
    end

    def supported_queries
      [:match, :term, :range]
    end
  end
end
