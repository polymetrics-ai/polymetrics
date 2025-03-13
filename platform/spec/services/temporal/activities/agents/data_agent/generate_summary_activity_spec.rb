# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::Agents::DataAgent::GenerateSummaryActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", logger: Rails.logger) }
  let(:activity) { described_class.new(activity_context) }
  let(:chat) { create(:chat) }
  let!(:user_message) { create(:message, chat: chat, role: :user, message_type: :question, content: "Sales summary") }
  let!(:pipeline_message) { create(:message, chat: chat, role: :assistant, message_type: :pipeline) }
  let(:pipeline) { create(:pipeline, message: pipeline_message) }
  let(:action_data) { [{ id: 1, amount: 100 }, { id: 2, amount: 200 }] }

  before do
    create(:pipeline_action,
           pipeline: pipeline,
           action_type: :query_execution,
           action_data: action_data)
    pipeline_message.update!(pipeline: pipeline)

    user_message
    pipeline_message
  end

  describe "#execute" do
    context "with valid chat data" do
      it "returns summary from service" do
        VCR.use_cassette("activities/generate_summary/success") do
          result = activity.execute(chat_id: chat.id)

          expect(result[:status]).to eq(:success)
          expect(result[:summary]).to be_a(String)
          expect(result[:timestamp]).to be_present
        end
      end
    end

    context "with missing data" do
      it "handles missing user query" do
        allow_any_instance_of(described_class).to receive(:execute)
          .and_raise(ArgumentError.new("User query is required"))

        expect { activity.execute(chat_id: chat.id) }
          .to raise_error(ArgumentError, "User query is required")
      end

      it "handles missing pipeline data" do
        pipeline.pipeline_actions.destroy_all

        result = activity.execute(chat_id: chat.id)
        expect(result[:status]).to eq(:error)
        expect(result[:error]).to include("Data results cannot be empty")
      end
    end

    context "when service fails" do
      before do
        allow_any_instance_of(Ai::SummaryGenerationService).to receive(:generate)
          .and_raise(StandardError.new("Generation failed"))
      end

      it "returns error response" do
        result = activity.execute(chat_id: chat.id)
        expect(result[:status]).to eq(:error)
        expect(result[:error]).to eq("Generation failed")
      end
    end
  end
end
