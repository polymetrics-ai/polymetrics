# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/duckdb_connector/writer"

RSpec.describe RubyConnectors::DuckdbConnector::Writer do
  subject(:writer) { described_class.new(config) }

  let(:config) do
    {
      database: "analytics_db_1",
      credentials: {
        local: {
          path: "analytics.duckdb"
        }
      }
    }
  end

  let(:db) { instance_double(DuckDB::Database) }
  let(:conn) { instance_double(DuckDB::Connection) }
  let(:appender) { instance_double(DuckDB::Appender) }

  before do
    # Mock DuckDB database operations
    allow(DuckDB::Database).to receive(:open).and_yield(db)
    allow(db).to receive(:connect).and_yield(conn)
    allow(conn).to receive_messages(
      appender: appender,
      query: [],
      execute: true,
      close: true
    )
    allow(appender).to receive_messages(
      append: true,
      end_row: true,
      flush: true,
      close: true
    )
  end

  describe "#initialize" do
    it "initializes with config" do
      expect(writer.instance_variable_get(:@config)).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end
  end

  describe "#write" do
    let(:data) { [{ "id" => 1, "name" => "Test" }] }
    let(:table_name) { "test_table" }
    let(:schema) { { "id" => "INTEGER", "name" => "VARCHAR" } }

    context "with valid parameters" do
      before do
        allow(conn).to receive(:query).and_return([])
        allow(conn).to receive(:execute)
      end

      it "writes data successfully" do
        writer.write(data, table_name: table_name, schema: schema)

        expect(conn).to have_received(:execute).with(/CREATE TABLE IF NOT EXISTS test_table/)
        expect(appender).to have_received(:append).twice
        expect(appender).to have_received(:flush)
        expect(appender).to have_received(:close)
      end

      it "handles schema creation when schema_name is provided" do
        allow(conn).to receive(:execute)

        writer.write(data, table_name: table_name, schema: schema, schema_name: "public")

        expect(conn).to have_received(:execute).with(/CREATE SCHEMA IF NOT EXISTS public/)
      end

      it "handles complex data types" do
        complex_data = [{ "id" => 1, "metadata" => { "key" => "value" } }]
        complex_schema = { "id" => "INTEGER", "metadata" => "JSON" }

        writer.write(complex_data, table_name: table_name, schema: complex_schema)

        expect(appender).to have_received(:append).with(1)
        expect(appender).to have_received(:append).with('{"key":"value"}')
      end

      it "creates table with single primary key" do
        writer.write(
          data,
          table_name: table_name,
          schema: schema,
          primary_keys: ["id"]
        )

        expect(conn).to have_received(:execute)
          .with(/CREATE TABLE IF NOT EXISTS test_table.*PRIMARY KEY \(id\)/m)
      end

      it "creates table with composite primary key" do
        writer.write(
          data,
          table_name: table_name,
          schema: schema,
          primary_keys: %w[id name]
        )

        expect(conn).to have_received(:execute)
          .with(/CREATE TABLE IF NOT EXISTS test_table.*PRIMARY KEY \(id, name\)/m)
      end
    end

    context "with invalid parameters" do
      it "raises error for invalid table name" do
        expect do
          writer.write(data, table_name: "invalid-table", schema: schema)
        end.to raise_error(ArgumentError, /Invalid identifiers found: table_name/)
      end

      it "raises error for invalid schema name" do
        expect do
          writer.write(data, table_name: table_name, schema: schema, schema_name: "invalid-schema")
        end.to raise_error(ArgumentError, /Invalid identifiers found: schema_name/)
      end

      it "validates multiple identifiers simultaneously" do
        expect do
          writer.write(data,
                       table_name: "invalid-table",
                       schema: schema,
                       schema_name: "invalid-schema",
                       database_name: "invalid-db")
        end.to raise_error(ArgumentError, /Invalid identifiers found: table_name, schema_name, database_name/)
      end

      it "raises error for invalid primary key field" do
        expect do
          writer.write(
            data,
            table_name: table_name,
            schema: schema,
            primary_keys: ["invalid_field"]
          )
        end.to raise_error(ArgumentError, /Invalid primary keys: invalid_field/)
      end

      it "raises error for invalid primary key format" do
        expect do
          writer.write(
            data,
            table_name: table_name,
            schema: schema,
            primary_keys: "id" # Should be an array
          )
        end.to raise_error(ArgumentError, /Primary keys must be an array/)
      end

      it "raises error for invalid primary key identifier" do
        expect do
          writer.write(
            data,
            table_name: table_name,
            schema: schema,
            primary_keys: ["invalid-id"]
          )
        end.to raise_error(ArgumentError, /Invalid primary key names: invalid-id/)
      end
    end

    context "when database operations fail" do
      it "handles schema creation failure" do
        allow(conn).to receive(:execute).with(/CREATE SCHEMA/).and_raise(DuckDB::Error, "Schema error")

        expect do
          writer.write(data, table_name: table_name, schema: schema, schema_name: "public")
        end.to raise_error(RubyConnectors::DuckdbConnector::WriteError, /Failed to create schema/)
      end

      it "handles table creation failure" do
        allow(conn).to receive(:query).and_return([])
        allow(conn).to receive(:execute).with(/CREATE TABLE/).and_raise(DuckDB::Error, "Table error")

        expect do
          writer.write(data, table_name: table_name, schema: schema)
        end.to raise_error(RubyConnectors::DuckdbConnector::WriteError, /Failed to create table/)
      end

      it "handles data insertion failure" do
        allow(conn).to receive(:query).and_return([])
        allow(conn).to receive(:execute)
        allow(appender).to receive(:append).and_raise(DuckDB::Error, "Insert error")

        expect do
          writer.write(data, table_name: table_name, schema: schema)
        end.to raise_error(RubyConnectors::DuckdbConnector::WriteError, /Failed to write data/)
      end
    end

    context "with empty data" do
      it "handles empty data array gracefully" do
        allow(conn).to receive(:query).and_return([])

        writer.write([], table_name: table_name, schema: schema)

        expect(conn).to have_received(:execute).with(/CREATE TABLE IF NOT EXISTS test_table/)
        expect(appender).not_to have_received(:append)
        expect(appender).not_to have_received(:end_row)
      end
    end
  end
end
