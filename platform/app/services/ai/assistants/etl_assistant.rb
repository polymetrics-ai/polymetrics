# frozen_string_literal: true

module Ai
  module Assistants
    class EtlAssistant
      SCHEMA_NAME = "etl_assistant"

      def initialize(workspace_id:, chat_id:, query:, llm: default_llm)
        @workspace_id = workspace_id
        @query = query
        @chat_id = chat_id
        @parser = build_parser
        @assistant = Langchain::Assistant.new(
          llm: llm,
          tools: build_tools,
          instructions: build_instructions
        )
        @chat = Chat.find(@chat_id)
      end

      def process_message
        @tool_calls = []

        @assistant.tool_execution_callback = lambda { |tool_call_id, tool_name, method_name, tool_arguments|
          @tool_calls << {
            id: tool_call_id,
            tool: tool_name,
            method: method_name,
            arguments: tool_arguments
          }
        }

        @assistant.add_message_and_run(
          content: @query
        )

        result = @assistant.run(auto_tool_execution: true)
        @chat.update!(tool_call_data: @tool_calls)
        format_response(result)
      end

      private

      def build_parser
        schema = Ai::ResponseSchemas::SchemaManager.fetch(SCHEMA_NAME)
        Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
      end

      def build_instructions
        base_instructions = Ai::Prompts::SystemPrompts.etl_assistant

        Langchain::Prompt::PromptTemplate.new(
          template: base_instructions,
          input_variables: ["format_instructions"]
        ).format(format_instructions: @parser.get_format_instructions)
      end

      def build_tools
        [
          Ai::Tools::Connector::ConnectorSelectionTool.new(workspace_id: @workspace_id, chat_id: @chat_id, original_query: @query),
          Ai::Tools::Connection::ConnectionCreationTool.new(workspace_id: @workspace_id, chat_id: @chat_id),
          Ai::Tools::Sync::SyncInitiatorTool.new(workspace_id: @workspace_id, chat_id: @chat_id),
          Ai::Tools::Query::QueryGenerationTool.new(workspace_id: @workspace_id, chat_id: @chat_id)
        ]
      end

      def default_llm
        # Langchain::LLM::Ollama.new(
        #   url: "http://localhost:11434",
        #   default_options: { temperature: 0.7, chat_model: "llama3.3", completion_model: "llama3.3", embedding_model: "llama3.3" }
        # )

        Langchain::LLM::OpenAI.new(
          api_key: ENV.fetch("OPENAI_API_KEY"),
          default_options: { temperature: 0.7, chat_model: "gpt-4o" }
        )
      end

      def format_response(_response)
        last_message = @assistant.messages.last

        begin
          parsed_response = @parser.parse(last_message.content)
        rescue Langchain::OutputParsers::OutputParserException
          fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
            llm: default_llm,
            parser: @parser
          )
          parsed_response = fix_parser.parse(last_message.content)
        end

        # Update chat with title and description if available
        if parsed_response["title"] || parsed_response["description"]
          @chat.update!(
            title: parsed_response["title"] || @chat.title,
            description: parsed_response["description"] || @chat.description
          )
        end

        {
          content: parsed_response,
          tool_calls: @tool_calls
        }
      end
    end
  end
end
