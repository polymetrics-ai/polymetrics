# frozen_string_literal: true

module RubyConnectors
  module Core
    class ApiCataloger
      def initialize(schemas_directory)
        @schemas_directory = schemas_directory
        @logger = Logger.new($stdout)
      end

      def catalog
        schemas = {}
        Dir.glob(File.join(@schemas_directory, "*.json")).each do |file|
          process_schema_file(file, schemas)
        end

        # Filter out schemas that don't have x-stream_name
        schemas.select { |_, schema| schema.key?("x-stream_name") }
      end

      private

      MAX_FILE_SIZE = 10 * 1024 * 1024 # 10MB limit

      def process_schema_file(file, schemas)
        return unless File.size(file) <= MAX_FILE_SIZE

        stream_name = File.basename(file, ".json")
        begin
          schema = File.open(file) { |f| JSON.parse(f.read) }
          schemas[stream_name] = schema if schema.key?("x-stream_name")
        rescue JSON::ParserError => e
          @logger.error("Failed to parse JSON file #{file}: #{e.message}")
        rescue StandardError => e
          @logger.error("Error processing file #{file}: #{e.message}")
        end
      end
    end
  end
end
