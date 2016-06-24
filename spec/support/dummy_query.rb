class DummyQuery
  def initialize(_query)
    @query = _query
  end

  def clone
    self.class.new @query
  end

  def render
    @query
  end

  def simplify
    return self
  end
end
