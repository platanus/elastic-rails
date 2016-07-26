module Elastic::Railties
  class ARMiddleware < Elastic::Core::BaseMiddleware
    def self.accepts?(_target)
      _target < ::ActiveRecord::Base
    end

    def mode
      :index # storage mode not supported for AR
    end

    def field_options_for(_field, _options)
      if Rails.version.to_f >= 4.2
        ARHelpers.infer_ar5_field_options(target, _field)
      else
        ARHelpers.infer_ar4_field_options(target, _field)
      end
    end

    def collect_all(_options, &_block)
      collect_from(target, _options, &_block)
    end

    def collect_from(_collection, _options, &_block)
      ARHelpers.find_each_with_options(
        _collection,
        includes: _options[:ar_collect_includes],
        scope: _options[:ar_collect_scope],
        &_block
      )
    end

    def find_by_ids(_ids, _options)
      results = target.where(id: _ids).order('id ASC')
      results = results.includes(_options[:ar_includes]) if _options.key? :ar_includes
      order_results _ids, results
    end

    private

    def order_results(_ordered_ids, _results)
      hash = _results.each_with_object({}) { |o, h| h[o.id] = o }
      _ordered_ids.map { |id| hash[id.to_i] }
    end
  end
end
