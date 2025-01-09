# frozen_string_literal: true

require "json-schema"
require "duckdb"

module RubyConnectors
  module DuckdbConnector
    class Connection
      def initialize(config)
        @config = config.with_indifferent_access
      end

      def connect
        db = authorize_connection
        check_connection(db)
        db.close
      end

      def authorize_connection
        if @config[:credentials].key?(:local)
          connect_local
        elsif @config[:credentials].key?(:motherduck)
          connect_motherduck
        else
          raise ArgumentError, "Invalid credentials configuration"
        end
      end

      private

      def connect_local
        path = @config[:credentials][:local][:path]
        DuckDB::Database.open(path)
      rescue DuckDB::Error => e
        raise ConnectionError, "Failed to connect to local DuckDB: #{e.message}"
      end

      def connect_motherduck
        token = @config[:credentials][:motherduck][:token]
        DuckDB::Database.open("md:?token=#{token}")
      rescue DuckDB::Error => e
        raise ConnectionError, "Failed to connect to MotherDuck: #{e.message}"
      end

      def check_connection(db)
        db.connect.query("SELECT 1").any?
      rescue DuckDB::Error => e
        raise ConnectionError, "Failed to verify DuckDB connection: #{e.message}"
      end
    end

    class ConnectionError < StandardError; end
  end
end
