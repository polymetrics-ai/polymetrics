# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::Prompts::SystemPrompts do
  describe ".etl_assistant" do
    it "returns ETL assistant prompt content" do
      mock_prompt = "ETL Assistant instructions..."
      allow(Ai::Prompts::Assistants::EtlAssistantPrompt).to receive(:content).and_return(mock_prompt)

      expect(described_class.etl_assistant).to eq(mock_prompt)
    end
  end

  describe ".connector_selection" do
    it "returns connector selection prompt with parameters" do
      connectors = %w[connector1 connector2]
      mock_prompt = "Connector selection instructions..."

      allow(Ai::Prompts::Tools::ConnectorSelectionPrompt)
        .to receive(:content)
        .with(connectors)
        .and_return(mock_prompt)

      expect(described_class.connector_selection(connectors)).to eq(mock_prompt)
    end
  end

  describe ".query_generation" do
    it "returns query generation prompt with parameters" do
      params = {
        destination_database_schemas: "schema_info",
        json_schemas: "json_schemas",
        query_requirements: "user_requirements"
      }
      mock_prompt = "Query generation instructions..."

      allow(Ai::Prompts::Tools::QueryGenerationPrompt)
        .to receive(:content)
        .with(params)
        .and_return(mock_prompt)

      expect(described_class.query_generation(**params)).to eq(mock_prompt)
    end
  end
end
