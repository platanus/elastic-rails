module Elastic::Core
  class DefaultMiddleware < BaseMiddleware
    def mode
      case target_mode
      when :find_multiple_ids, :find_single_id
        :index
      else
        :storage
      end
    end

    def field_options_for(_field, _options)
      nil
    end

    def collect_all(_options, &_block)
      method = collect_method_for(target)
      target.public_send(method, &_block) if method
    end

    def collect_from(_collection, _options, &_block)
      method = collect_method_for(_collection)
      raise ArgumentError, "Could not find a method to iterate over collection" if method.nil?
      _collection.public_send(method, &_block)
    end

    def find_by_ids(_ids, _options)
      case target_mode
      when :find_multiple_ids
        target.find_by_elastic_ids(_ids)
      when :find_single_id
        _ids.map { |id| target.find_by_elastic_id(id) }
      end
    end

    def build_from_data(_data, _options)
      case target_mode
      when :custom_build
        target.build_from_elastic_data(_data)
      when :open_struct
        OpenStruct.new _data
      end
    end

    private

    def target_mode
      @target_mode ||= detect_output_mode
    end

    def collect_method_for(_target)
      return :find_each_for_elastic if _target.respond_to?(:find_each_for_elastic)
      return :each if _target.respond_to?(:each)
      nil
    end

    def detect_output_mode
      return :find_multiple_ids if target.respond_to? :find_by_elastic_ids
      return :find_single_id if target.respond_to? :find_by_elastic_id
      return :custom_build if target.respond_to? :build_from_elastic_data
      :open_struct
    end
  end
end
