# frozen_string_literal: true

module Connectors
  class ListService
    CACHE_KEY = "connector_definitions"
    CACHE_EXPIRY = 1.hour

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
        load_connector_definitions
      end
    end

    private

    def load_connector_definitions
      yaml_content = load_yaml_file("config/connectors.yml")
      yaml_content["connectors"].map { |connector| build_connector_definition(connector) }
    end

    def load_yaml_file(file_path)
      YAML.load_file(Rails.root.join(file_path))
    end

    def build_connector_definition(connector)
      base_definition(connector).merge(
        icon_url: icon_url_for(connector["class_name"]),
        connection_specification: fetch_connection_specification(connector)
      )
    end

    def base_definition(connector)
      {
        name: connector["name"],
        type: connector["type"],
        language: connector["language"],
        class_name: connector["class_name"],
        operations: connector["operations"],
        definition_status: connector["definition_status"],
        version: connector["version"],
        maintainer: connector["maintainer"]
      }
    end

    def icon_url_for(class_name)
      "https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/#{class_name}.svg"
    end

    def fetch_connection_specification(connector)
      return nil unless ruby_connector?(connector)

      file_path = connection_specification_path(connector)
      return nil unless File.exist?(file_path)

      parse_connection_specification(file_path, connector)
    rescue JSON::ParserError => e
      log_json_parse_error(connector, e)
      nil
    end

    def ruby_connector?(connector)
      connector["language"].downcase == "ruby"
    end

    def connection_specification_path(connector)
      connector_folder = "#{connector["class_name"].underscore}_connector"
      connection_specification_paths(connector_folder)[:ruby]
    end

    def parse_connection_specification(file_path, _connector)
      specification = JSON.parse(File.read(file_path))
      inject_name_and_description(specification)
    end

    def log_json_parse_error(connector, error)
      Rails.logger.error("Error parsing connection specification for #{connector["name"]}: #{error.message}")
    end

    def connection_specification_paths(connector_folder)
      {
        ruby: Rails.root.join("ruby_connectors", "lib", "ruby_connectors", connector_folder,
                              "connection_specification.json").to_s,
        python: nil,
        javascript: nil
      }
    end

    def inject_name_and_description(specification)
      specification["properties"] = merge_name_and_description_properties(specification["properties"])
      specification["required"] = merge_required_fields(specification["required"])
      specification
    end

    def merge_name_and_description_properties(properties)
      new_properties = name_and_description_properties
      new_properties.merge(properties || {})
    end

    def name_and_description_properties
      {
        "name" => { "type" => "string", "title" => "Name", "description" => "The name of this connection" },
        "description" => { "type" => "string", "title" => "Description",
                           "description" => "A description of this connection" }
      }
    end

    def merge_required_fields(required)
      %w[name description] | (required || [])
    end
  end
end
