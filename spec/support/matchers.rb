RSpec::Matchers.define :support_aggregations do |*expected|
  match do |actual|
    next false unless actual.supported_aggregations.is_a? Array
    expected.all? { |n| actual.supported_aggregations.any? { |agg| agg == n } }
  end
end

RSpec::Matchers.define :forward do |method, options|
  params = options.fetch(:test_with, [:no_args])
  match do |actual|
    random = Random.rand
    allow(options[:to]).to receive(method).and_return random
    expect(actual.public_send(method, *params)).to eq random
    expect(options[:to]).to have_received(method).with(*params)
  end
end
