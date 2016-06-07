module Elastic::Capabilities
  module BoolQueryBuilder
    def minimum_should_match
      @minimum_should_match || 1
    end

    def minimum_should_match=(_value)
      @minimum_should_match = _value
    end

    def should_have(_field)
      set_context(:should_have, [should_parts, _field])
    end

    def must_have(_field)
      set_context(:must_have, [must_parts, _field])
    end

    def in(*_terms)
      with_context([:should_have, :must_have], :in) do |context, field|
        raise ArgumentError, 'must provide at least one term' if _terms.length == 0

        _terms = _terms.map { |t| transform_input(field, t) }

        context << (_terms.length > 1 ?
          { "terms" => { field.to_s => _terms } } :
          { "term" => { field.to_s => _terms.first } }
        )
      end
    end

    alias :equal_to :in

    def in_range(_range)
      with_context([:should_have, :must_have], :in_range) do |context, field|
        options = { }

        case _range
        when Range
          options['gte'] = _range.begin
          options['lt'] = _range.end if _range.exclude_end?
          options['lte'] = _range.end if !_range.exclude_end?
        when Hash
          [:gte, :gt, :lte, :lt].each do |opt|
            options[opt.to_s] = _range[opt] if _range.key? opt
          end
        else
          raise ArgumentError, 'must provide a range or a set of options'
        end

        context << { "range" => { field.to_s => options } }
      end
    end

    private

    def must_parts
      @must_parts ||= []
    end

    def should_parts
      @should_parts ||= []
    end

    def render_bool_query_to(_to)
      return if should_parts.length == 0 && must_parts.length == 0

      bool = _to['bool'] = {}
      bool['must'] = must_parts if must_parts.length > 0
      bool['should'] = should_parts if should_parts.length > 0
      bool['minimum_should_match'] = minimum_should_match if should_parts.length > 0
    end
  end
end
