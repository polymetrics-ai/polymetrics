# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Ai
  module Tools
    module Query
      class QueryGenerationTool < BaseTool
        SCHEMA_NAME = "query_generation_tool"

        define_function(
          :generate_query,
          description: "Generates SQL query based on destination schema and stream schema"
        ) do
          property :query_requirements,
                   type: "string",
                   description: "Natural language description of query requirements",
                   required: true
        end

        def initialize(workspace_id:, chat_id:)
          @workspace_id = workspace_id
          @chat_id = chat_id
          @chat = Chat.find(@chat_id)
          @parser = build_parser
        end

        def generate_query(query_requirements:)
          syncs = @chat.connections.flat_map(&:syncs)
          destination_schemas, json_schemas = prepare_schemas(syncs)

          return { status: :error, error: "Destination schema is missing" } if destination_schemas.compact.empty?
          return { status: :error, error: "JSON schema is missing" } if json_schemas.compact.empty?

          parsed_response = build_and_send_prompt(
            destination_schemas,
            json_schemas,
            query_requirements
          )

          handle_response_type(parsed_response)
          handle_success(parsed_response)
        end

        private

        def prepare_schemas(syncs)
          [
            syncs.map(&:destination_database_schema),
            syncs.map(&:schema)
          ]
        end

        def build_and_send_prompt(destination_schemas, json_schemas, query_requirements)
          prompt = build_prompt(
            destination_database_schemas: destination_schemas,
            json_schemas: json_schemas,
            query_requirements: query_requirements
          )

          raw_response = default_llm.chat(messages: [{ role: "user", content: prompt }]).completion
          @parser.parse(raw_response)
        end

        def handle_response_type(parsed_response)
          case parsed_response["type"]
          when "pipeline_action" then handle_pipeline_action(parsed_response)
          when "message" then handle_message_action(parsed_response)
          end
        end

        def build_prompt(destination_database_schemas:, json_schemas:, query_requirements:)
          Ai::Prompts::SystemPrompts.query_generation(
            destination_database_schemas: destination_database_schemas,
            json_schemas: json_schemas,
            query_requirements: query_requirements
          ).gsub("{format_instructions}", @parser.get_format_instructions)
        end

        def build_parser
          schema = Ai::ResponseSchemas::SchemaManager.fetch(SCHEMA_NAME)
          Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
        end

        def default_llm
          # Langchain::LLM::Ollama.new(
          #   url: "http://localhost:11434",
          #   default_options: { temperature: 0.7,
          #                       chat_model: "deepseek-r1:70b",
          #                       completion_model: "deepseek-r1:70b",
          #                       embedding_model: "deepseek-r1:70b" })

          Langchain::LLM::OpenAI.new(
            api_key: ENV.fetch("OPENROUTER_API_KEY"),
            llm_options: { uri_base: "https://openrouter.ai/api/v1" },
            default_options: { temperature: 0.7, chat_model: "deepseek/deepseek-chat" }
          )
        end

        def handle_pipeline_action(parsed_response)
          parsed_response["content"].each do |content|
            next unless content["action_type"] == "query_execution"

            create_pipeline_for_content(content)
          end
        end

        def create_pipeline_for_content(content)
          return if action_exists?(content)

          pipeline_message = find_or_create_pipeline_message(content)
          pipeline = pipeline_message.pipeline || pipeline_message.create_pipeline!(status: :pending)
          create_pipeline_action(pipeline, content)
        end

        def find_or_create_pipeline_message(_content)
          @chat.messages.find_by(message_type: :pipeline) ||
            @chat.messages.create!(
              role: :assistant,
              content: {},
              message_type: :pipeline,
              answered: true
            )
        end

        def action_exists?(content)
          pipeline_message = @chat.messages.find_by(message_type: :pipeline)
          return false unless pipeline_message&.pipeline

          pipeline_message.pipeline.pipeline_actions.exists?(
            action_type: :query_execution,
            action_data: JSON.parse(content["action_data"].to_json)
          )
        end

        def create_pipeline_action(pipeline, content)
          next_position = pipeline.pipeline_actions.maximum(:position).to_i + 1

          pipeline.pipeline_actions.create!(
            action_type: :query_execution,
            position: next_position,
            action_data: JSON.parse(content["action_data"].to_json)
          )
        end

        def handle_message_action(parsed_response)
          parsed_response["content"].each do |content|
            create_question_message(content)
          end
        end

        def create_question_message(content)
          @chat.messages.create!(
            content: content["message"],
            role: :assistant,
            message_type: :question,
            answered: false
          )
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
