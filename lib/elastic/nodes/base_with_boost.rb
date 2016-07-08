module Elastic::Nodes
  class BaseWithBoost < Base
    attr_accessor :boost

    private

    def base_clone
      clone = super
      clone.boost = @boost unless @boost.nil?
      clone
    end

    def render_boost(_hash)
      _hash['boost'] = @boost.to_f unless @boost.nil?
      _hash
    end
  end
end
