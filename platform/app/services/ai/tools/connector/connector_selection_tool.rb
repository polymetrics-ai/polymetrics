# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Ai
  module Tools
    module Connector
      class ConnectorSelectionTool < BaseTool
        SCHEMA_NAME = "connector_selection_tool"

        define_function(
          :find_connectors,
          description: "Find appropriate connectors based on user query and requirements"
        ) do
          property :query,
                   type: "string",
                   description: "User query and requirements",
                   required: true
        end

        def initialize(workspace_id:, chat_id:, original_query:)
          # Enable this when using Ollama
          # Faraday.default_connection_options = Faraday::ConnectionOptions.new({ timeout: 84000 })
          @workspace_id = workspace_id
          @chat_id = chat_id
          @original_query = original_query
          @parser = build_parser
          @chat = Chat.find(@chat_id)
        rescue Ai::ResponseSchemas::SchemaNotFoundError => e
          Rails.logger.error("Failed to initialize ConnectorSelectionTool: #{e.message}")
        end

        def find_connectors(query:)
          @query = query
          connectors = fetch_workspace_connectors
          return handle_error("No connectors found in the workspace") unless connectors.any?

          response_content = fetch_llm_response(connectors, @original_query)
          process_parsed_response(response_content)
        rescue Langchain::OutputParsers::OutputParserException => e
          handle_parser_error(e)
        end

        private

        def fetch_workspace_connectors
          ::Connector.where(workspace_id: @workspace_id)
        end

        def fetch_llm_response(connectors, query)
          prompt_text = create_prompt_text(connectors, query)
          message = [{ role: "user", content: prompt_text }]
          response = default_llm.chat(messages: message)
          # response.raw_response["message"]["content"]
          response.completion
        end

        def process_parsed_response(content)
          parsed_response = @parser.parse(content)

          case parsed_response["type"]
          when "pipeline_action"
            handle_pipeline_action(parsed_response)
          when "message"
            handle_message_action(parsed_response)
          end

          handle_success(parsed_response)
        end

        def handle_pipeline_action(parsed_response)
          parsed_response["content"].each do |content|
            next unless content["action_type"] == "connection_creation"

            ActiveRecord::Base.transaction do
              create_pipeline_for_content(content)
            end
          end
        end

        def create_pipeline_for_content(content)
          return if action_exists?(content)

          pipeline_message = create_pipeline_message(content)
          pipeline = create_pipeline(pipeline_message)
          create_pipeline_action(pipeline, content)
        end

        def create_pipeline_message(content)
          @chat.messages.create!(
            content: content["action_data"].to_json,
            role: :assistant,
            message_type: :pipeline,
            answered: true
          )
        end

        def create_pipeline(message)
          message.create_pipeline!(status: :pending)
        end

        def action_exists?(_content)
          # First check if a pipeline message exists
          pipeline_message = @chat.messages.find_by(message_type: :pipeline)
          return false unless pipeline_message

          # Then check if the pipeline has a connection_creation action
          pipeline_message.pipeline&.pipeline_actions&.exists?(
            action_type: :connection_creation
          ) || false
        end

        def create_pipeline_action(pipeline, content)
          pipeline.pipeline_actions.create!(
            action_type: :connection_creation,
            position: 0,
            action_data: content["action_data"].to_json
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

        def handle_parser_error(error)
          fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
            llm: default_llm,
            parser: @parser
          )
          handle_success(fix_parser.parse(error.message))
        end

        def create_prompt_text(connectors, query)
          base_prompt = Ai::Prompts::SystemPrompts.connector_selection(connectors)
          prompt = Langchain::Prompt::PromptTemplate.new(
            template: base_prompt,
            input_variables: %w[query format_instructions]
          )
          prompt.format(query: query, format_instructions: @parser.get_format_instructions)
        end

        def build_parser
          schema = Ai::ResponseSchemas::SchemaManager.fetch(SCHEMA_NAME)
          Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
        end

        def default_llm
          # Langchain::LLM::Ollama.new(
          #   url: "http://localhost:11434",
          #   default_options: { temperature: 0.7,
          #     chat_model: "deepseek-r1:70b",
          #     completion_model: "deepseek-r1:70b",
          #     embedding_model: "deepseek-r1:70b" }
          # )

          Langchain::LLM::OpenAI.new(
            api_key: ENV.fetch("OPENROUTER_API_KEY"),
            llm_options: { uri_base: "https://openrouter.ai/api/v1" },
            default_options: { temperature: 0.7, chat_model: "deepseek/deepseek-chat" }
          )
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
