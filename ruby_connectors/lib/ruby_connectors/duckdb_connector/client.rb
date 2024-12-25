# frozen_string_literal: true

module RubyConnectors
  module DuckdbConnector
    class Client < Core::BaseConnector
      def initialize(config)
        super
        @connection = RubyConnectors::DuckdbConnector::Connection.new(config)
        @writer = RubyConnectors::DuckdbConnector::Writer.new(config)
      end

      def connect
        @connection.connect
      end

      def write(data, table_name:, schema:, schema_name: nil, database_name: nil, primary_keys: nil)
        @writer.write(
          data,
          table_name: table_name,
          schema: schema,
          schema_name: schema_name,
          database_name: database_name,
          primary_keys: primary_keys
        )
      end
    end
  end
end
