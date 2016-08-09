module Elastic::Datatypes
  class Term < Default
    def mapping_options
      options = super
      options[:type] = 'string'
      options[:index] = 'not_analyzed'
      options
    end
  end
end
