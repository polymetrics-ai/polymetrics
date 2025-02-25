# frozen_string_literal: true

module RubyConnectors
  module DuckdbConnector
    class Reader
      DEFAULT_LIMIT = 10000

      def initialize(config)
        @config = config.with_indifferent_access
      end

      def read(table_name: nil, query: nil, offset: 0, limit: DEFAULT_LIMIT)
        validate_parameters(table_name, query)
        
        DuckDB::Database.open(@config.dig(:credentials, :path)) do |db|
          db.connect do |conn|
            if query.present?
              has_semicolon = query.strip.end_with?("\;")
              base_query = has_semicolon ? query[0...-1] : query
            else
              base_query = "SELECT * FROM #{table_name}"
            end

            existing_limit, existing_offset = parse_limit_offset(base_query)

            if existing_limit && existing_limit <= limit
              # Use existing limit if it's smaller than requested limit
              paginated_query = base_query
              effective_limit = existing_limit
              effective_offset = existing_offset || 0
            else
              # Apply new pagination
              paginated_query = apply_pagination(base_query, offset, limit)
              effective_limit = limit
              effective_offset = offset
            end

            {
              data: execute_query(conn, paginated_query),
              offset: effective_offset,
              limit: effective_limit,
              total_records: get_total_records(conn, base_query)
            }
          end
        end
      rescue DuckDB::Error => e
        raise ReadError, "DuckDB read error: #{e.message}"
      end

      private

      def validate_parameters(table_name, query)
        return if query || table_name

        raise ArgumentError, "Must provide either table_name or query"
      end

      def get_total_records(conn, base_query)
        count_query = "SELECT COUNT(*) FROM (#{base_query}) AS subquery"
        conn.query(count_query).first[0].to_i
      end

      def execute_query(conn, query)
        result = conn.query(query)
        
        # Get column names once
        columns = result.columns.map(&:name)
        
        # Convert rows to hashes using column names
        result.map do |row|
          columns.zip(row).to_h
        end
      end

      def parse_limit_offset(query)
        # Match only the final LIMIT/OFFSET clause using end-of-query anchor
        match = query.match(/^(.*?)(?:\s+LIMIT\s+(\d+)(?:\s+OFFSET\s+(\d+))?)?\s*;?$/i)
        return [nil, nil] unless match[2]

        limit = match[2].to_i
        offset = match[3]&.to_i
        [limit, offset]
      end

      def apply_pagination(base_query, offset, limit)
        # Remove only the final LIMIT/OFFSET clause and any trailing semicolon
        cleaned_query = base_query.sub(/\s+LIMIT\s+\d+(?:\s+OFFSET\s+\d+)?\s*;?$/i, '').strip
        # Add new pagination and preserve original semicolon if present
        "#{cleaned_query} LIMIT #{limit} OFFSET #{offset}"
      end
    end

    class ReadError < StandardError; end
  end
end 