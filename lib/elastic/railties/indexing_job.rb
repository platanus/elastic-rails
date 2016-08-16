module Elastic::Railties
  class IndexingJob < ActiveJob::Base
    def perform(*_indexables)
      # TODO: use import for many indexables
      _indexables.each &:index_now
    end
  end
end
