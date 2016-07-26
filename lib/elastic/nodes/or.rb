module Elastic::Nodes
  class Or < And
    private

    def operation
      'or'
    end
  end
end
