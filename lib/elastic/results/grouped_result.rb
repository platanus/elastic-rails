module Elastic::Results
  class GroupedResult < Base
    include Enumerable

    attr_reader :key_names

    def initialize(_key_names, _groups)
      @key_names = _key_names.freeze
      @groups = _groups.to_a
    end

    def each(&_block)
      @groups.map { |g| group_as_pair g }.each(&_block)
    end

    def [](_key)
      if _key.is_a? Hash
        mapped_results[_key]
      else
        raise ArgumentError, '' if @key_names.length > 1
        mapped_results[@key_names.first => _key]
      end
    end

    def each_group(&_block)
      @groups.each(&_block)
    end

    def last
      return nil if @groups.count == 0
      group_as_pair @groups.last
    end

    def count
      @groups.count
    end

    def group_at(_idx)
      @groups[_idx]
    end

    def traverse(&_block)
      super
      @groups.each { |h| h.traverse(&_block) }
    end

    def map_to_group(&_block)
      self.class.new(@key_names, @groups.map do |group|
        Elastic::Results::ResultGroup.new group.keys, _block.call(group.as_value)
      end)
    end

    private

    def group_as_pair(_group)
      [_group.keys, _group.as_value]
    end

    def mapped_results
      @mapped_results ||= {}.tap do |map|
        @groups.each do |g|
          map[g.keys] = g.as_value
        end
      end
    end
  end
end
