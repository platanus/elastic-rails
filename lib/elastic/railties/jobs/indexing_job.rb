module Elastic::Railties::Jobs
  class IndexingJob < ActiveJob::Base
    def perform(_type, _document)
      _type.constantize.connector.index _document
    end
  end
end
