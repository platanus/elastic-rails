require 'spec_helper'

describe Elastic::Configuration do
  let(:custom_logger) { Logger.new(STDOUT) }
  let(:custom_api_client) { define_custom_api_client }
  let(:custom_time_zone) { define_custom_time_zone }
  let(:config) { described_class.new }

  context 'when initialize without arguments' do
    describe 'has default attributes' do
      it { expect(config.host).to eq '127.0.0.1' }
      it { expect(config.port).to be 9200 }
      it { expect(config.page_size).to be(20) }
      it { expect(config.coord_similarity).to be true }
      it { expect(config.import_batch_size).to be 10_000 }
      it { expect(config.whiny_indices).to be false }
      it { expect(config.disable_indexing).to be false }
      it { expect(config.disable_index_name_caching).to be false }
      it { expect(config.logger).to be_a(Logger) }
      it { expect(config.time_zone).to be_a(ActiveSupport::TimeZone) }
      it {
        expect(config.api_client).to be_a(
          Elasticsearch::Transport::Client
        )
      }
    end
  end

  context 'when assign custom attributes' do
    it 'api_client' do
      config.api_client = custom_api_client
      expect(config.api_client).to be(custom_api_client)
    end

    it 'logger' do
      config.logger = custom_logger
      expect(config.logger).to be(custom_logger)
    end

    it 'time_zone' do
      config.time_zone = custom_time_zone
      expect(config.time_zone).to be(custom_time_zone)
    end

    # Just test assignations because this parameters are
    # sended to Elasticsearch::Transport::Client
    it 'host and port' do
      config.host = '192.168.1.23'
      config.port = 9201
      expect(config.host).to eq('192.168.1.23')
      expect(config.port).to eq(9201)
    end

    it 'adapter' do
      config.adapter = :patron
      expect(config.adapter).to eq(:patron)
    end
  end

  # Helpers
  def define_custom_api_client
    Elasticsearch::Client.new host: '192.168.30.3', port: 9205
  end

  def define_custom_logger
    Logger.new(STDOUT)
  end

  def define_custom_time_zone
    ActiveSupport::TimeZone.new('Santiago')
  end
end
