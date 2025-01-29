# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::Agents::DataAgent::ProcessMessageActivity do
  let(:workspace) { create(:workspace) }
  let(:chat) { create(:chat, workspace: workspace) }
  let(:activity_context) { instance_double("Temporal::Activity::Context", logger: Rails.logger) }
  let(:activity) { described_class.new(activity_context) }
  let(:content) { "Test query" }
  let(:assistant_instance) { instance_double(Ai::Assistants::EtlAssistant) }

  describe "#execute" do
    context "when message processing succeeds" do
      let(:mock_response) do
        {
          content: "Processed response",
          tool_calls: [{ "name" => "test_tool" }]
        }
      end

      before do
        allow(Ai::Assistants::EtlAssistant).to receive(:new).and_return(assistant_instance)
        allow(assistant_instance).to receive(:process_message).and_return(mock_response)
      end

      it "returns success response with content" do
        result = activity.execute(
          workspace_id: workspace.id,
          chat_id: chat.id,
          content: content
        )

        expect(result).to include(
          status: :success,
          content: mock_response[:content],
          tool_calls: mock_response[:tool_calls]
        )
      end

      it "initializes the assistant with correct parameters" do
        activity.execute(
          workspace_id: workspace.id,
          chat_id: chat.id,
          content: content
        )

        expect(Ai::Assistants::EtlAssistant).to have_received(:new).with(
          workspace_id: workspace.id,
          chat_id: chat.id,
          query: content
        )
      end
    end

    context "when processing fails" do
      let(:error_message) { "Processing error" }

      before do
        allow(Ai::Assistants::EtlAssistant).to receive(:new).and_return(assistant_instance)
        allow(assistant_instance).to receive(:process_message).and_raise(StandardError.new(error_message))
      end

      it "returns error response" do
        result = activity.execute(
          workspace_id: workspace.id,
          chat_id: chat.id,
          content: content
        )

        expect(result).to include(
          status: :error,
          error: error_message
        )
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Message processing failed/)
        activity.execute(
          workspace_id: workspace.id,
          chat_id: chat.id,
          content: content
        )
      end
    end
  end

  describe "configuration" do
    it "has correct timeouts" do
      expect(described_class.instance_variable_get(:@timeouts))
        .to eq(start_to_close: 36_000)
    end
  end
end
