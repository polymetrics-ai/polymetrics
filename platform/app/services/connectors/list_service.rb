# frozen_string_literal: true

module Connectors
  class ListService
    def call
      Rails.cache.fetch("connector_definitions", expires_in: 1.hour) do
        load_connector_definitions
      end
    end

    private

    def load_connector_definitions
      yaml_content = YAML.load_file(Rails.root.join("config/connectors.yml"))
      connectors = yaml_content["connectors"]
      connectors.map { |connector| build_connector_definition(connector) }
    end

    def build_connector_definition(connector)
      {
        name: connector["name"],
        type: connector["type"],
        language: connector["language"],
        class_name: connector["class_name"],
        operations: connector["operations"],
        status: connector["status"],
        version: connector["version"],
        maintainer: connector["maintainer"]
        # icon_url: icon_url_for(connector['class_name'])
      }
    end
  end
end
