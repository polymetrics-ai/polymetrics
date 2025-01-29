# frozen_string_literal: true

module Ai
  module Prompts
    class SystemPrompts
      class << self
        def etl_assistant
          Ai::Prompts::Assistants::EtlAssistantPrompt.content
        end

        def connector_selection(connectors)
          Ai::Prompts::Tools::ConnectorSelectionPrompt.content(connectors)
        end

        def query_generation(destination_database_schemas:, json_schemas:, query_requirements:)
          Ai::Prompts::Tools::QueryGenerationPrompt.content(destination_database_schemas: destination_database_schemas, json_schemas: json_schemas,
                                                            query_requirements: query_requirements)
        end
      end
    end
  end
end
