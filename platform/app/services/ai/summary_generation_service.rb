# frozen_string_literal: true

module Ai
  class SummaryGenerationService
    SCHEMA_NAME = "summary_generation_tool"

    def generate(user_query:, data_results:, additional_context: nil)
      @llm = default_llm
      @parser = build_parser
      validate_inputs!(user_query, data_results)

      prompt = build_prompt(
        user_query: user_query,
        data_results: data_results,
        additional_context: additional_context
      )

      raw_response = @llm.chat(messages: [{ role: "user", content: prompt }]).completion
      @parser.parse(raw_response)
    end

    private

    def validate_inputs!(user_query, data_results)
      raise ArgumentError, "User query is required" if user_query.blank?
      raise ArgumentError, "Data results cannot be empty" if data_results.blank?
    end

    def build_prompt(user_query:, data_results:, additional_context: nil)
      base_prompt = Ai::Prompts::SystemPrompts.summary_generation(
        user_query: user_query,
        data_results: data_results,
        additional_context: additional_context
      )

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
        default_options: { temperature: 0.7, chat_model: "google/gemini-2.0-flash-exp:free" }
      )
    end
  end
end
