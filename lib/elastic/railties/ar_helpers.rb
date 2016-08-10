module Elastic::Railties
  module ARHelpers
    extend self

    def find_each_with_options(_collection, includes: nil, scope: nil, &_block)
      if _collection.respond_to? :find_each
        _collection = _collection.includes(*includes) if includes
        _collection = _collection.send(scope) if scope
        _collection.find_each(&_block)
      elsif _collection.respond_to? :each
        ActiveRecord::Associations::Preloader.new.preload(_collection, *includes) if includes
        _collection.each(&_block)
      else
        raise 'Elastic ActiveRecord importing is only supported for collection types'
      end
    end

    def infer_ar4_field_options(_klass, _field)
      # TODO: consider methods occluded by an override:
      # AR defines methods, this wont work: return nil if _klass.method_defined? _field

      return nil unless _klass.serialized_attributes[_field].nil? # occluded by serializer
      return nil if _klass.columns_hash[_field].nil?
      ar_type_to_options _klass.columns_hash[_field].type
    end

    def infer_ar5_field_options(_klass, _field)
      # TODO: consider methods occluded by an override:
      # AR defines methods, this wont work: return nil if _klass.method_defined? _field

      meta = _klass.type_for_attribute _field
      return nil if meta.to_s == 'ActiveRecord::Type::Serialized' # occluded by serializer
      ar_type_to_options meta.type
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def ar_type_to_options(_type)
      case _type.try(:to_sym)
      when :text              then { type: :string }
      when :string            then { type: :string, index: 'not_analyzed' }
      when :integer           then { type: :long } # not sure..
      when :float, :decimal   then { type: :double } # not sure..
      when :date              then { type: :date }
      when :datetime          then { type: :time }
      when :boolean           then { type: :boolean }
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
