module Elastic::Nodes
  module Boostable
    attr_accessor :boost

    def clone
      copy_boost super
    end

    def simplify
      copy_boost super
    end

    private

    def copy_boost(_clone)
      _clone.boost = @boost
      _clone
    end

    def render_boost(_hash)
      _hash['boost'] = @boost.to_f unless @boost.nil?
      _hash
    end
  end
end
