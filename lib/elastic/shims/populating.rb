module Elastic::Shims
  class Populating < Base
    def initialize(_index, _config, _child)
      super _child
      @index = _index
      @config = _config
    end

    def render(_options = {})
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
      child.pick_nodes(Elastic::Nodes::Concerns::HitProvider) do |node|
        node.source = false
      end
    end

    def populate(_result)
      hits = _result.pick_nodes(Elastic::Results::Hit).to_a

      if populate_by_id?
        ids = hits.map(&:id)
        objects = target.find_by_ids(ids, middleware_options)
        objects.each_with_index { |o, i| hits[i].data = o }
      else
        hits.each do |hit|
          hit.data = @index.definition.target.build_from_data(hit.source, middleware_options)
        end
      end
    end

    def populate_by_id?
      @index.definition.mode == :index
    end

    def target
      @index.definition.target
    end

    def middleware_options
      @middleware_options ||= begin
        @index.definition.middleware_options.merge(@config.middleware_options).freeze
      end
    end
  end
end
