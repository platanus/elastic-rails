module Elastic::Support
  module Traversable
    def traverse(&_block)
      raise NotImplementedError, "every traversable tree must implement 'traverse'"
    end

    def pick(*_types, &_block)
      if _types.empty?
        enum = Enumerator.new do |y|
          traverse { |h| y << h }
        end
      else
        enum = Enumerator.new do |y|
          traverse { |h| y << h if _types.any? { |t| h.is_a? t } }
        end
      end

      return enum if _block.nil?
      enum.each(&_block)
    end
  end
end
