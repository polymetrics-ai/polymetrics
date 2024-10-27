# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/duckdb_connector/client"
require "vcr"

RSpec.describe RubyConnectors::DuckdbConnector::Client do
  subject(:client) { described_class.new(config) }

  let(:config) do
    {
      database: "md:my_database",
      credentials: {
        motherduck: {
          token: ENV.fetch("MOTHERDUCK_TOKEN", nil)
        }
      }
    }
  end

  describe "#initialize" do
    let(:connection) { instance_spy(RubyConnectors::DuckdbConnector::Connection) }

    it "creates a new connection" do
      allow(RubyConnectors::DuckdbConnector::Connection).to receive(:new).and_return(connection)
      client
      expect(RubyConnectors::DuckdbConnector::Connection).to have_received(:new).with(config)
    end
  end

  describe "#connect" do
    it "connects to the database" do
      VCR.use_cassette("duckdb/motherduck_connect") do
        expect(client.connect).to be true
      end
    end
  end
end
