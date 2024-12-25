# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/duckdb_connector/client"

RSpec.describe RubyConnectors::DuckdbConnector::Client do
  subject(:client) { described_class.new(config) }

  let(:config) do
    {
      database: "test_db",
      credentials: {
        local: {
          path: "test.duckdb"
        }
      }
    }
  end

  let(:writer) { instance_double(RubyConnectors::DuckdbConnector::Writer) }
  let(:connection) { instance_double(RubyConnectors::DuckdbConnector::Connection) }
  let(:data) { [{ "id" => 1, "name" => "Test" }] }
  let(:table_name) { "test_table" }
  let(:schema) { { "type" => "object" } }
  let(:schema_name) { "public" }
  let(:database_name) { "test_db" }

  before do
    allow(RubyConnectors::DuckdbConnector::Writer).to receive(:new).and_return(writer)
    allow(RubyConnectors::DuckdbConnector::Connection).to receive(:new).and_return(connection)
    allow(writer).to receive(:write)
    allow(connection).to receive(:connect).and_return(true)
  end

  describe "#write" do
    it "delegates write operation to writer with all parameters" do
      client.write(
        data,
        table_name: table_name,
        schema: schema,
        schema_name: schema_name,
        database_name: database_name
      )

      expect(writer).to have_received(:write).with(
        data,
        table_name: table_name,
        schema: schema,
        schema_name: schema_name,
        database_name: database_name,
        primary_keys: nil
      )
    end

    it "delegates write operation to writer with minimal parameters" do
      client.write(
        data,
        table_name: table_name,
        schema: schema
      )

      expect(writer).to have_received(:write).with(
        data,
        table_name: table_name,
        schema: schema,
        schema_name: nil,
        database_name: nil,
        primary_keys: nil
      )
    end

    it "delegates write operation with primary keys" do
      primary_keys = ["id"]
      client.write(
        data,
        table_name: table_name,
        schema: schema,
        primary_keys: primary_keys
      )

      expect(writer).to have_received(:write).with(
        data,
        table_name: table_name,
        schema: schema,
        schema_name: nil,
        database_name: nil,
        primary_keys: primary_keys
      )
    end
  end

  describe "#connect" do
    it "connects to the database" do
      expect(client.connect).to be true
      expect(connection).to have_received(:connect)
    end
  end
end
