# frozen_string_literal: true

module Ai
  class SqlGenerationService
    SCHEMA_NAME = "query_generation_tool"

    def initialize(chat_id:, sample_data: nil, llm: nil)
      @chat_id = chat_id
      @sample_data = sample_data || load_sample_data_from_syncs
      @llm = llm || default_llm
      @parser = build_parser
    end

    def generate(destination_schemas:, json_schemas:, query_requirements:)
      validate_schemas!(destination_schemas, json_schemas)

      prompt = build_prompt(
        destination_database_schemas: destination_schemas,
        json_schemas: json_schemas,
        query_requirements: query_requirements,
        sample_data: @sample_data
      )

      raw_response = @llm.chat(messages: [{ role: "user", content: prompt }]).completion
      @parser.parse(raw_response)
    end

    private

    def validate_schemas!(destination_schemas, json_schemas)
      raise ArgumentError, "Destination schema is missing" if destination_schemas.compact.empty?
      raise ArgumentError, "JSON schema is missing" if json_schemas.compact.empty?
    end

    def build_prompt(destination_database_schemas:, json_schemas:, query_requirements:, sample_data: nil)
      base_prompt = Ai::Prompts::SystemPrompts.query_generation(
        destination_database_schemas: destination_database_schemas,
        json_schemas: json_schemas,
        query_requirements: query_requirements
      )

      base_prompt += "\n\nSample Data:\n#{sample_data.to_json}" if sample_data

      base_prompt.gsub("{format_instructions}", @parser.get_format_instructions)
    end

    def build_parser
      schema = Ai::ResponseSchemas::SchemaManager.fetch(SCHEMA_NAME)
      Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
    end

    def default_llm
      Langchain::LLM::OpenAI.new(
        api_key: ENV.fetch("OPENROUTER_API_KEY"),
        llm_options: { uri_base: "https://openrouter.ai/api/v1" },
        default_options: { temperature: 0.7, chat_model: "deepseek/deepseek-chat" }
      )
    end

    def load_sample_data_from_syncs
      chat = Chat.find(@chat_id)
      return unless chat.connections.any?

      # Get first record from last sync run of each connection
      sample_data = chat.connections.flat_map do |connection|
        next unless connection.syncs.any?

        last_sync = connection.syncs.last
        next unless last_sync

        # Get stored data using workflow store service
        last_sync.sync_read_records.first.data[0]
      end.compact

      sample_data.presence
    end
  end
end
