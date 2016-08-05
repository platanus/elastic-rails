module Elastic::Shims
  class Populating < Base
    def initialize(_index, _config, _child)
      super _child
      @index = _index
      @config = _config
    end

    def render
      disable_hits_source if populate_by_id?
      super
    end

    def handle_result(_raw, _formatter)
      result = super
      populate result
      result
    end

    private

    def disable_hits_source
      child.pick(Elastic::Nodes::Concerns::HitProvider) do |node|
        node.source = false
      end
    end

    def populate(_result)
      groups = _result.pick(Elastic::Results::Hit).group_by(&:type)
      groups.each { |t, h| populate_group(t, h) }
    end

    def populate_group(_type_name, _hits)
      target = resolve_target(_type_name)
      raise "Unexpected type name #{_type_name}" if target.nil?

      if populate_by_id?
        ids = _hits.map(&:id)
        objects = target.find_by_ids(ids, middleware_options)
        objects.each_with_index { |o, i| _hits[i].data = o }
      else
        _hits.each do |hit|
          hit.data = target.build_from_data(
            formatter.format(hit.source),
            middleware_options
          )
        end
      end
    end

    def populate_by_id?
      @index.definition.mode == :index
    end

    def resolve_target(_type_name)
      @index.definition.targets.find { |t| t.type_name == _type_name }
    end

    def middleware_options
      @middleware_options ||= begin
        @index.definition.middleware_options.merge(@config.middleware_options).freeze
      end
    end

    def formatter
      @formatter ||= Elastic::Core::SourceFormatter.new(@index.mapping)
    end
  end
end
