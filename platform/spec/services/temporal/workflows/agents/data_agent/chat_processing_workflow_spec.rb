# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Agents::DataAgent::ChatProcessingWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata") }
  let(:workflow_context) do
    instance_double("WorkflowContext",
                    logger: double("Logger", error: nil),
                    metadata: workflow_metadata)
  end
  let(:chat) { create(:chat) }
  let(:params) do
    {
      "chat_id" => chat.id,
      "content" => "Test message",
      "workspace_id" => chat.workspace.id
    }
  end

  before do
    # Mock activities
    allow(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to receive(:execute!)
    allow(Temporal::Activities::Agents::DataAgent::ChatProcessingActivity).to receive(:execute!)
  end

  describe "#execute" do
    context "when message processing succeeds" do
      let(:mock_response) do
        {
          status: :success,
          content: "Processed response",
          tool_calls: []
        }
      end

      before do
        allow(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to receive(:execute!)
          .and_return(mock_response)
      end

      it "processes the message through activities" do
        workflow.execute(params)

        expect(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to have_received(:execute!).with(
          workspace_id: chat.workspace.id,
          chat_id: chat.id,
          content: "Test message"
        )
      end

      it "returns success structure" do
        result = workflow.execute(params)

        expect(result).to include(
          status: :success,
          chat_id: chat.id,
          content: "Processed response"
        )
      end
    end

    context "when message processing fails" do
      before do
        allow(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to receive(:execute!)
          .and_return({ status: :error, error: "Processing failed" })
      end

      it "handles the error through chat processing activity" do
        workflow.execute(params)

        expect(Temporal::Activities::Agents::DataAgent::ChatProcessingActivity).to have_received(:execute!).with(
          chat_id: chat.id,
          status: :error,
          error_message: "Processing failed"
        )
      end

      it "returns error structure" do
        result = workflow.execute(params)

        expect(result).to include(
          status: :error,
          chat_id: chat.id,
          error: "Processing failed"
        )
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to receive(:execute!)
          .and_raise(StandardError.new("Critical failure"))
      end

      it "logs the error" do
        expect(workflow_context.logger).to receive(:error).with(/Chat processing failed: Critical failure/)
        workflow.execute(params)
      end

      it "returns error response" do
        result = workflow.execute(params)
        expect(result[:status]).to eq(:error)
      end
    end
  end
end
