# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/duckdb_connector/client"
require "vcr"

RSpec.describe RubyConnectors::DuckdbConnector::Client do
  let(:config) do
    {
      database: 'md:my_database',
      credentials: {
        motherduck: {
          token: ENV['MOTHERDUCK_TOKEN']
        }
      }
    }
  end

  subject(:client) { described_class.new(config) }

  describe '#initialize' do
    it 'creates a new connection' do
      expect(RubyConnectors::DuckdbConnector::Connection).to receive(:new).with(config)
      client
    end
  end

  describe '#connect' do
    it 'connects to the database' do
      VCR.use_cassette('duckdb/motherduck_connect') do
        expect(client.connect).to be true
      end
    end
  end
end