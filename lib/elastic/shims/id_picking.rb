module Elastic::Shims
  class IdPicking < Base
    include Elastic::Shims::Concerns::HitPicker

    private

    def pick_from_hit(_hit)
      _hit.id
    end

    def required_source_fields
      false
    end
  end
end
