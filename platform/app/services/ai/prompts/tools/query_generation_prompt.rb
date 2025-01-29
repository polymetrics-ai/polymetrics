# frozen_string_literal: true

module Ai
  module Prompts
    module Tools
      class QueryGenerationPrompt
        def self.content(destination_database_schemas:, json_schemas:, query_requirements:)
          schemas = process_schemas(destination_database_schemas)

          <<~INSTRUCTIONS
            You are an expert SQL query generator.
            Based on the following information, create a SQL SELECT query that includes joins between multiple tables according to the specified database syntax.

            #{format_table_names(schemas)}
            #{format_schema_names(schemas)}
            #{format_json_schemas(json_schemas)}
            **Database Type**: duckDB

            #{format_requirements}
            #{format_example_output}
            ### Your Task:
            #{query_requirements}

            {format_instructions}
          INSTRUCTIONS
        end

        def self.process_schemas(schemas)
          Array(schemas).compact
        end

        def self.format_table_names(schemas)
          table_names = schemas.filter_map { |s| s["table_name"] }.join(", ") || "N/A"
          "**Table Names**:\n#{table_names}"
        end

        def self.format_schema_names(schemas)
          schema_names = schemas.filter_map { |s| s["schema_name"] }.uniq.join(", ") || "N/A"
          "**Schema Names**:\n#{schema_names}"
        end

        def self.format_json_schemas(schemas)
          json = schemas.present? ? schemas.to_json : "No schema available"
          "**JSON Schemas**:\n#{json}"
        end

        def self.format_requirements
          <<~REQS.chomp
            ### Requirements:
            - Include any necessary WHERE conditions based on user input.
            - Specify the columns to select from each table.
            - Ensure that the syntax aligns with the specified database type.
            - Ensure we have schema names and table names along with the json schema else return an error message.
          REQS
        end

        def self.format_example_output
          "### Example Output:\nProvide a complete SQL SELECT statement based on the above information."
        end
      end
    end
  end
end
