RSpec::Matchers.define :support_aggregations do |*expected|
  match do |actual|
    next false unless actual.supported_aggregations.is_a? Array
    expected.all? { |n| actual.supported_aggregations.any? { |agg| agg[:type].to_sym == n } }
  end
end
