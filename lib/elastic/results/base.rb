module Elastic::Results
  class Base
    def each_hit(&_block)
      # nothing by default
    end

    def all_hits
      Enumerator.new do |y|
        each_hit { |h| y << h }
      end
    end
  end
end
