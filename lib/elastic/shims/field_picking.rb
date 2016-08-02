module Elastic::Shims
  class FieldPicking < Base
    include Elastic::Shims::Concerns::HitPicker

    def initialize(_child, _field)
      super(_child)
      @field = _field
    end

    private

    def pick_from_hit(_hit)
      _hit.source[@field]
    end

    def required_source_fields
      [@field]
    end
  end
end
