module Elastic::Datatypes
  class Term < Default
    def mapping_options
      options = super
      options[:type] = 'keyword'
      options
    end
  end
end
