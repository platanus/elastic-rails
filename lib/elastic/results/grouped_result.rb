module Elastic::Results
  class GroupedResult < Base
    extend Forwardable
    include Enumerable

    def_delegators :@groups, :last, :first, :count, :[], :each

    def initialize(_groups)
      @groups = _groups
    end

    def traverse(&_block)
      super
      @groups.each { |h| h.traverse(&_block) }
    end
  end
end
