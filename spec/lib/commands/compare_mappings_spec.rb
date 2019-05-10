require 'spec_helper'

describe Elastic::Commands::CompareMappings do
  def perform(_options)
    described_class.for(_options)
  end

  it "returns the properties that are in user but not in current" do
    user = {
      'properties' => {
        'foo' => { 'type' => 'keyword' },
        'qux' => { 'type' => 'integer' },
        'baz' => { 'type' => 'integer' }
      }
    }

    current = {
      'properties' => {
        'foo' => { 'type' => 'keyword' },
        'bar' => { 'type' => 'keyword' }
      }
    }

    expect(perform(current: current, user: user)).to eq(['qux', 'baz'])
  end

  it "returns user properties that are different from current properties" do
    user = {
      'properties' => {
        'foo' => { 'type' => 'string' },
        'bar' => { 'type' => 'string' }
      }
    }

    current = {
      'properties' => {
        'foo' => { 'type' => 'string' },
        'bar' => { 'type' => 'integer' }
      }
    }

    expect(perform(current: current, user: user)).to eq(['bar'])
  end

  it "properly handles nested properties" do
    user = {
      'properties' => {
        'foo' => {
          'type' => 'nested',
          'properties' => {
            'bar' => { 'type' => 'long' },
            'baz' => { 'type' => 'long' }
          }
        }
      }
    }

    current = {
      'properties' => {
        'foo' => {
          'type' => 'nested',
          'properties' => {
            'bar' => { 'type' => 'string' },
            'baz' => { 'type' => 'long' }
          }
        }
      }
    }

    expect(perform(current: current, user: user)).to eq(['foo.bar'])
  end

  it "properly handles date defaults" do
    user = {
      'properties' => {
        'foo' => { 'type' => 'date' }
      }
    }

    current = {
      'properties' => {
        'foo' => { 'type' => 'date', 'format' => 'dateOptionalTime' }
      }
    }

    expect(perform(current: current, user: user)).to eq([])
  end
end
