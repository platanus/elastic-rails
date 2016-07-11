module Elastic::Railties
  module ARHelpers
    extend self

    def infer_ar4_field_options(_klass, _field)
      return nil if _klass.method_defined? _field # occluded by method override
      return nil unless _klass.serialized_attributes[_field].nil? # occluded by serializer
      return nil if _klass.columns_hash[_field].nil?
      ar_type_to_options _klass.columns_hash[_field].type
    end

    def infer_ar5_field_options(_klass, _field)
      return nil if _klass.method_defined? _field # occluded by method override
      meta = _klass.type_for_attribute _field
      return nil if meta.to_s? == 'ActiveRecord::Type::Serialized' # occluded by serializer
      ar_type_to_options meta.type
    end

    private

    def ar_type_to_options(_type)
      case _type.try(:to_sym)
      when :text              then { type: :string }
      when :string            then { type: :string, index: 'not_analyzed' }
      when :integer           then { type: :long } # not sure..
      when :float, :decimal   then { type: :double } # not sure..
      when :datetime, :date   then { type: :date }
      when :boolean           then { type: :boolean }
      else nil end
    end
  end
end