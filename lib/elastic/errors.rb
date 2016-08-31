module Elastic
  class Error < StandardError
  end

  class MissingIndexError < Error
  end

  class RolloverError < Error
  end
end
