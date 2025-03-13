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
    allow(Temporal::Activities::Agents::DataAgent::ProcessMessageActivity).to receive(:execute!)
    allow(Temporal::Activities::Agents::DataAgent::ChatProcessingActivity).to receive(:execute!)
    allow(Temporal::Activities::Agents::DataAgent::CheckConnectionHealthActivity).to receive(:execute!)
    allow(Temporal::Activities::Agents::DataAgent::GenerateSummaryActivity).to receive(:execute!)
    allow(Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow).to receive(:execute!)
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
        allow(Temporal::Activities::Agents::DataAgent::CheckConnectionHealthActivity).to receive(:execute!)
          .and_return(recently_synced_healthy_connection_ids: [])
        allow(Temporal::Activities::Agents::DataAgent::GenerateSummaryActivity).to receive(:execute!)
          .and_return(summary: "Test summary")
      end

      it "executes the full processing flow" do
        # Mock signal handling
        completed_connections = Set.new
        allow(workflow_context).to receive(:on_signal)
          .with("connection_healthy") do |&block|
            completed_connections.add(1)
            block.call(connection_id: 1)
          end

        # Mock wait_until to simulate completed connections
        allow(workflow_context).to receive(:wait_until) do |&block|
          block.call
          true
        end

        result = workflow.execute(params)

        expect(result).to include(
          status: :success,
          chat_id: chat.id,
          content: "Processed response"
        )
      end

      it "starts ProcessAssistantQueryWorkflow with correct parameters" do
        allow(workflow_context).to receive(:on_signal)
        allow(workflow_context).to receive(:wait_until).and_return(true)

        workflow.execute(params)

        expect(Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow).to have_received(:execute!).with(
          chat.id,
          options: {
            task_queue: "platform_queue",
            workflow_id: "process_assistant_query_workflow-chat_id-#{chat.id}"
          }
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
    end
  end
end
