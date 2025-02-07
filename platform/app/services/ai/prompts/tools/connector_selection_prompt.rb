# frozen_string_literal: true

module Ai
  module Prompts
    module Tools
      class ConnectorSelectionPrompt
        def self.content(connectors)
          <<~INSTRUCTIONS
            You are a Data Integration Assistant specialized in creating data pipelines. Your role is to help users set up source-to-destination data connections based on their requirements.

            Available connectors in the workspace:
            #{format_connector_details(connectors)}

            Instructions:
            1. Analyze the user's query to understand their data integration needs
            2. Identify appropriate source which will be an API connector based on the query and destination which will be a database connector
            3. For source connectors:
               - Match requirements with available API connectors and their streams
               - Consider data structure, required fields, and primary keys
            4. For destination:
               - Use the default analytics database (marked as default_analytics_db: true)
            5. If the query is ambiguous or needs clarification, ask appropriate questions

            {format_instructions}

            User Query: {query}

            Remember:
            - Source must be an API connector
            - Always use the exact stream names given in the connector stream descriptions
            - Destination must be a database connector
            - Validate stream compatibility and field mappings
            - If multiple options exist, include all only one api source for one connection creation
            - If clarification needed, ask specific questions
            - Consider data types and structure compatibility
            - Only return the JSON response
          INSTRUCTIONS
        end

        def self.format_connector_details(connectors)
          api_connectors, db_connectors = connectors.partition { |c| c.integration_type == "api" }

          <<~DETAILS
            API Connectors:
            #{format_api_connectors(api_connectors)}

            Database Connectors:
            #{format_db_connectors(db_connectors)}
          DETAILS
        end

        def self.format_api_connectors(connectors)
          connectors.map { |connector| format_connector(connector) + format_api_connector_streams(connector) }.join("\n\n")
        end

        def self.format_db_connectors(connectors)
          connectors.map { |connector| format_connector(connector) }.join("\n\n")
        end

        def self.format_connector(connector)
          <<~CONNECTOR.chomp
            Connector Name: #{connector.name}
            Connector ID: #{connector.id}
            Integration Type: #{connector.integration_type}
            Connector Language: #{connector.connector_language}
            Default Analytics DB: #{connector.default_analytics_db ? "Yes" : "No"}
            Connector Configuration: #{sanitize_configuration(connector.configuration)}
          CONNECTOR
        end

        def self.format_api_connector_streams(connector)
          streams = connector.stream_descriptions.map do |stream|
            <<~STREAM
              - #{stream[:name]}:
                Description: #{stream[:description]}
                Sync modes: #{stream[:sync_modes].join(", ")}
                Primary Key: #{stream[:primary_key]&.join(", ") || "None"}
                Required Fields: #{stream[:required_fields]&.join(", ") || "None"}
            STREAM
          end.join("\n")

          "\nAvailable Streams:\n#{streams}"
        end

        def self.sanitize_configuration(config)
          sanitized = config.deep_dup
          %w[password api_key secret token].each do |sensitive_field|
            sanitized.delete(sensitive_field)
          end
          sanitized.to_yaml
        end
      end
    end
  end
end
