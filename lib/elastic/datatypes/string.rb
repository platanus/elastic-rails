module Elastic::Datatypes
  class String < Default
    def supported_queries
      [:match, :term, :range]
    end
  end
end
