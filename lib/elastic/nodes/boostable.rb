module Elastic::Nodes
  module Boostable
    attr_accessor :boost

    def self.included(_klass)
      _klass.clone_and_simplify_with { |c| c.boost = @boost }
    end

    private

    def render_boost(_hash)
      _hash['boost'] = @boost.to_f unless @boost.nil?
      _hash
    end
  end
end
