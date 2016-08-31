module Elastic::Railties::Jobs
  class DeletingJob < ActiveJob::Base
    def perform(_type, _document)
      _type.constantize.connector.delete _document
    end
  end
end
