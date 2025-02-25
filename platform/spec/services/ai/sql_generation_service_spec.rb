# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::SqlGenerationService do
  subject(:service) { described_class.new(chat_id: chat.id) }

  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:connection) { create(:connection, workspace: workspace) }
  let(:sync) do
    create(:sync,
           connection: connection,
           destination_database_schema: {
             database: "test_db",
             table_name: "sales",
             schema_name: "ecommerce",
             table_schema: {
               product_id: "INTEGER",
               category: "VARCHAR",
               sale_amount: "DECIMAL",
               sale_date: "DATE"
             }
           },
           schema: {
             "type" => "object",
             "properties" => {
               "product_id" => { "type" => "integer" },
               "category" => { "type" => "string" },
               "sale_amount" => { "type" => "number" },
               "sale_date" => { "type" => "string", "format" => "date" }
             }
           })
  end

  let(:destination_schemas) { [sync.destination_database_schema] }
  let(:json_schemas) { [sync.schema] }
  let(:query_requirements) { "Show me total sales by product category" }

  let(:sample_data) do
    [{
      "product_id" => 1,
      "category" => "Electronics",
      "sale_amount" => 1000.00,
      "sale_date" => "2024-01-01"
    }]
  end

  before do
    connection
    sync
    chat.connections << connection

    # Create sample sync read record
    create(:sync_read_record, sync: sync, data: sample_data)
  end

  describe "#generate" do
    context "with valid schemas and requirements" do
      it "generates SQL query successfully" do
        VCR.use_cassette("sql_generation/valid_query") do
          result = service.generate(
            destination_schemas: destination_schemas,
            json_schemas: json_schemas,
            query_requirements: query_requirements
          )

          expect(result["type"]).to eq("pipeline_action")
          expect(result["content"]).to be_an(Array)
          expect(result["content"].first).to include(
            "action_type" => "query_generation",
            "action_data" => include(
              "query" => include("SELECT"),
              "explanation" => be_present
            )
          )
        end
      end

      it "includes sample data in the prompt when available" do
        VCR.use_cassette("sql_generation/with_sample_data") do
          result = service.generate(
            destination_schemas: destination_schemas,
            json_schemas: json_schemas,
            query_requirements: query_requirements
          )

          expect(result["content"].first["action_data"]["explanation"]).to be_present
        end
      end
    end

    context "with invalid schemas" do
      it "raises error for missing destination schema" do
        expect do
          service.generate(
            destination_schemas: [],
            json_schemas: json_schemas,
            query_requirements: query_requirements
          )
        end.to raise_error(ArgumentError, "Destination schema is missing")
      end

      it "raises error for missing JSON schema" do
        expect do
          service.generate(
            destination_schemas: destination_schemas,
            json_schemas: [],
            query_requirements: query_requirements
          )
        end.to raise_error(ArgumentError, "JSON schema is missing")
      end
    end

    context "with custom LLM" do
      let(:custom_llm) { instance_double(Langchain::LLM::OpenAI) }
      let(:custom_service) { described_class.new(chat_id: chat.id, llm: custom_llm) }
      let(:llm_response) do
        instance_double("Response", completion: {
          type: "pipeline_action",
          content: [{
            action_type: "query_generation",
            action_data: {
              query: "SELECT category, SUM(sale_amount) AS total_sales FROM sales GROUP BY category",
              explanation: "Test explanation",
              warnings: []
            }
          }]
        }.to_json)
      end

      before do
        allow(custom_llm).to receive(:chat).and_return(llm_response)
      end

      it "uses the provided LLM" do
        VCR.use_cassette("sql_generation/custom_llm") do
          result = custom_service.generate(
            destination_schemas: destination_schemas,
            json_schemas: json_schemas,
            query_requirements: query_requirements
          )

          expect(custom_llm).to have_received(:chat)
          expect(result["content"].first["action_data"]).to include(
            "query" => be_present,
            "explanation" => be_present
          )
        end
      end
    end
  end
end
