# frozen_string_literal: true

# # frozen_string_literal: true

# require "rails_helper"

# RSpec.describe Ai::Tools::Query::QueryGenerationTool do
#   subject { described_class.new(workspace_id: workspace.id, chat_id: chat.id) }

#   let(:workspace) { create(:workspace) }
#   let(:chat) { create(:chat, workspace: workspace) }
#   let(:connection) { create(:connection, workspace: workspace) }
#   let(:sync) do
#     create(:sync,
#            connection: connection,
#            destination_database_schema: {
#              database: "polymetrics_ai_inc_development",
#              table_name: "sales",
#              schema_name: "ecommerce",
#              table_schema: {
#                product_id: "INTEGER",
#                category: "VARCHAR",
#                sale_amount: "DECIMAL",
#                sale_date: "DATE"
#              }
#            },
#            schema: {
#              "type" => "object",
#              "properties" => {
#                "product_id" => { "type" => "integer" },
#                "category" => { "type" => "string" },
#                "sale_amount" => { "type" => "number" },
#                "sale_date" => { "type" => "string", "format" => "date" }
#              }
#            })
#   end

#   before do
#     connection
#     sync
#     chat.connections << connection
#   end

#   describe "#generate_query" do
#     let(:query_requirements) { "Show me total sales by product category" }

#     context "with valid schema data" do
#       it "generates a SQL query and creates pipeline message" do
#         VCR.use_cassette("query_generation/valid_schema", record: :once) do
#           result = subject.generate_query(query_requirements: query_requirements)

#           expect(result[:status]).to eq(:success)
#           expect(chat.messages.pipeline).to exist
#           expect(chat.pipelines).to exist
#         end
#       end
#     end

#     context "with invalid schema data" do
#       before do
#         sync.update!(destination_database_schema: nil)
#       end

#       it "returns an error message" do
#         result = subject.generate_query(query_requirements: query_requirements)

#         expect(result[:status]).to eq(:error)
#         expect(result[:error]).to include("Destination schema is missing")
#       end
#     end
#   end

#   describe "private methods" do
#     describe "#build_prompt" do
#       it "includes schema data and requirements" do
#         prompt = subject.send(:build_prompt,
#                               destination_database_schemas: [{}],
#                               json_schemas: [{}],
#                               query_requirements: "test requirements")

#         expect(prompt).to include("test requirements")
#         expect(prompt).to include("JSON Schema")
#       end
#     end
#   end
# end
