module Elastic::Commands
  class InferFieldOptions < Command.new(:klass, :field)
    def perform
      if klass.respond_to? :get_field_index_type
        { type: klass.get_field_index_type }
      elsif is_ar_5?
        infer_type_from_ar_5_target
      elsif is_ar_4?
        infer_type_from_ar_4_target
      else
        nil
      end
    end

    private

    def is_ar_4?
      klass.respond_to? :columns_hash
    end

    def is_ar_5?
      klass.respond_to? :type_for_attribute
    end

    def infer_type_from_ar_4_target
      return nil if klass.method_defined? field # occluded by method override
      return nil unless klass.serialized_attributes[field].nil? # occluded by serializer
      return nil if klass.columns_hash[field].nil?
      ar_type_to_options(klass.columns_hash[field].type)
    end

    def infer_type_from_ar_5_target
      return nil if klass.method_defined? field # occluded by method override
      meta = klass.type_for_attribute(field)
      return nil if meta.to_s == 'ActiveRecord::Type::Serialized' # occluded by serializer
      ar_type_to_options(meta.type)
    end

    def ar_type_to_options(_type)
      puts _type
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