# frozen_string_literal: true

module Syncs
  # rubocop:disable Metrics/ClassLength
  class DestinationSchemaNormalizerService
    def initialize(sync)
      @sync = sync
      @source_connector = sync.connection.source
      @destination_connector = sync.connection.destination
      @stream_name = sync.stream_name
      @workspace_id = sync.connection.workspace_id
    end

    def call
      return nil unless database_destination?

      {
        database: generate_database_name,
        schema_name: schema_support? ? generate_schema_name : nil,
        table_name: generate_table_name(@stream_name),
        table_schema: generate_table_schema,
        mapping: generate_mapping
      }
    end

    private

    def generate_table_schema
      schema = {
        "_polymetrics_id" => map_field_type({ "type" => "string" })["type"],
        "_polymetrics_extracted_at" => map_field_type({ "type" => "string", "format" => "date-time" })["type"]
      }

      if source_schema && source_schema["properties"]
        source_schema["properties"].each do |field_name, field_definition|
          schema[field_name.to_s] = map_field_type(field_definition)["type"]
        end
      end

      schema
    end

    def generate_mapping
      default_mappings + source_field_mappings
    end

    def default_mappings
      [
        {
          from: "_polymetrics_id",
          to: "_polymetrics_id",
          type: "signature"
        },
        {
          from: "_polymetrics_extracted_at",
          to: "_polymetrics_extracted_at",
          type: "current_timestamp"
        }
      ]
    end

    def source_field_mappings
      return [] unless source_schema["properties"]

      source_schema["properties"].keys.map do |field_name|
        {
          from: field_name,
          to: field_name,
          type: "default"
        }
      end
    end

    def map_field_type(field_schema)
      mapping = load_destination_mapping

      type = extract_non_null_type(field_schema["type"])
      format = field_schema["format"]

      db_type = if format && mapping[:format_mappings]&.[](format)
                  mapping[:format_mappings][format]
                elsif type && mapping[:type_mappings]&.[](type)
                  mapping[:type_mappings][type]
                else
                  mapping[:default]
                end

      { "type" => db_type }
    end

    def extract_non_null_type(type)
      return type unless type.is_a?(Array)

      non_null_types = type.reject { |t| t == "null" }
      non_null_types.first || "string"
    end

    def generate_schema_name
      source_name = @sync.connection.source.name.downcase
                         .parameterize(separator: "_")
                         .gsub(/[^a-z0-9_]/, "")
      workspace_hash = Digest::SHA256.hexdigest(@workspace_id.to_s)[0..15]

      "#{source_name}_#{workspace_hash}"
    end

    def generate_database_name
      org_name = @sync.connection.workspace.organization.name
                      .downcase
                      .parameterize(separator: "_")
                      .gsub(/[^a-z0-9_]/, "")
      environment = Rails.env

      "#{org_name}_#{environment}"
    end

    def generate_table_name(base_name)
      if schema_support?
        base_name
      else
        "#{generate_schema_name}_#{base_name}"
      end
    end

    def schema_support?
      @schema_support ||= begin
        metadata = load_destination_metadata
        metadata.dig("features", "schema_support") || false
      rescue StandardError => e
        Rails.logger.error("Error loading metadata file: #{e.message}")
        false
      end
    end

    def load_destination_metadata
      path = metadata_file_path
      JSON.parse(File.read(path))
    end

    def load_destination_mapping
      @load_destination_mapping ||= begin
        path = mapping_file_path
        JSON.parse(File.read(path)).with_indifferent_access
      rescue StandardError => e
        Rails.logger.error("Error loading mapping file: #{e.message}")
        {}
      end
    end

    def metadata_file_path
      build_connector_file_path("metadata.json")
    end

    def mapping_file_path
      build_connector_file_path("mapping.json")
    end

    def build_connector_file_path(filename)
      connector_folder = "#{@destination_connector.connector_class_name.underscore}_connector"
      Rails.root.join("..", "ruby_connectors", "lib", "ruby_connectors",
                      connector_folder, filename)
    end

    def database_destination?
      @destination_connector.integration_type == "database"
    end

    def source_schema
      @source_schema ||= @sync.schema || {}
    end
  end
  # rubocop:enable Metrics/ClassLength
end
