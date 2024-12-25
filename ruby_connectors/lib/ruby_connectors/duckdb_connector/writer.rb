# frozen_string_literal: true

module RubyConnectors
  module DuckdbConnector
    class Writer
      VALID_IDENTIFIER_REGEX = /^[a-zA-Z_][a-zA-Z0-9_]*$/

      def initialize(config)
        @config = config.with_indifferent_access
        @connection = Connection.new(config)
      end

      def write(data, table_name:, schema:, schema_name: nil, database_name: nil, primary_keys: nil)
        validate_identifiers!(table_name: table_name, schema_name: schema_name, database_name: database_name)
        validate_primary_keys!(primary_keys, schema) if primary_keys

        with_connection do |conn|
          ensure_schema_exists(conn, schema_name) if schema_name
          create_table(conn, table_name, schema, schema_name, primary_keys)

          write_data(conn, data, table_name, schema_name, schema) unless data.empty?
        end
      end

      private

      def with_connection
        db = @connection.authorize_connection
        conn = db.connect
        yield(conn)
      ensure
        conn&.close
      end

      def validate_identifiers!(table_name:, schema_name:, database_name:)
        invalid_identifiers = collect_invalid_identifiers(
          table_name: table_name,
          schema_name: schema_name,
          database_name: database_name
        )

        return if invalid_identifiers.empty?

        raise ArgumentError, "Invalid identifiers found: #{invalid_identifiers.join(", ")}"
      end

      def validate_primary_keys!(primary_keys, schema)
        return if primary_keys.nil? || primary_keys.empty?

        raise ArgumentError, "Primary keys must be an array" unless primary_keys.is_a?(Array)

        invalid_names = primary_keys.reject { |key| valid_identifier?(key) }
        raise ArgumentError, "Invalid primary key names: #{invalid_names.join(", ")}" if invalid_names.any?

        invalid_keys = primary_keys.reject { |key| schema.key?(key) }
        return unless invalid_keys.any?

          raise ArgumentError, "Invalid primary keys: #{invalid_keys.join(", ")}. Keys must exist in schema"
      end

      def collect_invalid_identifiers(identifiers)
        identifiers.each_with_object([]) do |(key, value), invalid|
          invalid << key.to_s if value && !valid_identifier?(value)
        end
      end

      def valid_identifier?(name)
        return false unless name.is_a?(String)

        name.match?(VALID_IDENTIFIER_REGEX)
      end

      def ensure_schema_exists(conn, schema_name)
        return unless schema_name

        execute_sql(conn, "CREATE SCHEMA IF NOT EXISTS #{schema_name}")
      rescue DuckDB::Error => e
        raise WriteError, "Failed to create schema #{schema_name}: #{e.message}"
      end

      def create_table(conn, table_name, schema, schema_name, primary_keys)
        full_table_name = build_table_name(table_name, schema_name)
        columns = build_columns_definition(schema)
        pk_constraint = build_primary_key_constraint(primary_keys)

        execute_sql(conn, <<-SQL)
          CREATE TABLE IF NOT EXISTS #{full_table_name} (
            #{columns}#{pk_constraint}
          )
        SQL
      rescue DuckDB::Error => e
        raise WriteError, "Failed to create table #{full_table_name}: #{e.message}"
      end

      def build_primary_key_constraint(primary_keys)
        return "" unless primary_keys&.any?

        ",\n  PRIMARY KEY (#{primary_keys.join(", ")})"
      end

      def write_data(conn, data, table_name, schema_name, schema)
        return if data.empty?

        full_table_name = build_table_name(table_name, schema_name)
        write_with_appender(conn, full_table_name, data, schema)
      rescue DuckDB::Error => e
        raise WriteError, "Failed to write data to #{full_table_name}: #{e.message}"
      end

      def write_with_appender(conn, full_table_name, data, schema)
        appender = nil
        begin
          # Start transaction explicitly
          conn.execute("BEGIN TRANSACTION")

          appender = conn.appender(full_table_name)
          data.each { |record| append_record(appender, record, schema) }

          # Flush and close appender before committing
          appender.flush
          appender.close
          appender = nil

          # Commit transaction
          conn.execute("COMMIT")
        rescue StandardError => e
          # Rollback on error
          begin
            conn.execute("ROLLBACK")
          rescue StandardError
            nil
          end
          raise WriteError, "Failed to write data: #{e.message}"
        ensure
          # Make sure appender is closed
          if appender
            begin
              appender.close
            rescue StandardError
              nil
            end
          end
        end
      end

      def append_record(appender, record, schema)
        schema.each_key do |column|
          value = format_value(record[column])
          appender.append(value)
        end
        appender.end_row
      end

      def format_value(value)
        return value.to_json if value.is_a?(Hash) || value.is_a?(Array)

        value
      end

      def build_table_name(table_name, schema_name)
        return table_name unless schema_name

        "#{schema_name}.#{table_name}"
      end

      def build_columns_definition(schema)
        schema.map do |column_name, data_type|
          "#{column_name} #{map_data_type(data_type)}"
        end.join(",\n  ")
      end

      def map_data_type(data_type)
        data_type.to_s.upcase
      end

      def execute_sql(conn, sql)
        conn.execute(sql.squish)
      end
    end

    class WriteError < StandardError; end
  end
end
