# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ai::SummaryGenerationService, :vcr do
  let(:service) { described_class.new }
  let(:valid_data) { [{ id: 1, content: "Q1 sales: $1.2M" }, { id: 2, content: "Q2 sales: $1.5M" }] }
  let(:valid_query) { "Provide quarterly sales summary" }

  describe "#generate" do
    context "with valid inputs" do
      it "returns structured summary" do
        VCR.use_cassette("services/ai/summary_generation_service/generate") do
          result = service.generate(
            user_query: valid_query,
            data_results: valid_data,
            additional_context: "Focus on growth trends"
          )

          expect(result).to be_a(Hash)
          expect(result).to include("summary")
          expect(result["summary"]).to be_a(String)
        end
      end
    end

    context "with invalid inputs" do
      it "raises error for blank user query" do
        expect { service.generate(user_query: "", data_results: valid_data) }
          .to raise_error(ArgumentError, "User query is required")
      end

      it "raises error for empty data results" do
        expect { service.generate(user_query: valid_query, data_results: []) }
          .to raise_error(ArgumentError, "Data results cannot be empty")
      end
    end
  end
end
