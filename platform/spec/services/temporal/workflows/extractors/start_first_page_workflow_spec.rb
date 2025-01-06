# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Extractors::StartFirstPageWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_context) { instance_double("WorkflowContext", logger: logger) }
  let(:logger) { instance_double("Logger") }

  let(:sync_run_id) { 123 }
  let(:workflow_params) do
    {
      workflow_params: {
        some_param: "value"
      }
    }
  end
  let(:workflow_id) { "read_first_page_api_data_workflow-sync_run_id_#{sync_run_id}" }

  # Mock Temporal client
  before do
    # Stub ENV fetch for task queue
    allow(ENV).to receive(:fetch).with("TEMPORAL_TASK_QUEUE", "ruby_connectors_queue")
                                 .and_return("test_queue")
  end

  describe "#execute" do
    context "when execution is successful" do
      let(:run_id) { "test_run_id_456" }

      before do
        allow(Temporal).to receive(:start_workflow).and_return(run_id)
      end

      it "starts the workflow and returns success response" do
        result = workflow.execute(sync_run_id: sync_run_id, workflow_params: workflow_params)

        expect(Temporal).to have_received(:start_workflow).with(
          "RubyConnectors::Temporal::Workflows::ReadFirstPageApiDataWorkflow",
          workflow_params[:workflow_params].merge(workflow_id: workflow_id),
          options: {
            workflow_id: workflow_id,
            task_queue: "test_queue"
          }
        )

        expect(result).to eq({
                               workflow_id: workflow_id,
                               run_id: run_id,
                               success: true
                             })
      end
    end

    context "with invalid parameters" do
      it "raises error when sync_run_id is nil" do
        expect do
          workflow.execute(sync_run_id: nil, workflow_params: workflow_params)
        end.to raise_error(ArgumentError, "sync_run_id cannot be nil")
      end

      it "raises error when workflow_params is nil" do
        expect do
          workflow.execute(sync_run_id: sync_run_id, workflow_params: nil)
        end.to raise_error(ArgumentError, "workflow_params cannot be nil")
      end

      it "raises error when workflow_params is not a hash" do
        expect do
          workflow.execute(sync_run_id: sync_run_id, workflow_params: "not a hash")
        end.to raise_error(ArgumentError, "workflow_params must be a Hash")
      end
    end

    context "when workflow_params structure is invalid" do
      let(:invalid_params) { { invalid_key: "value" } }

      before do
        allow(logger).to receive(:error)
        # Mock Temporal to simulate normal behavior but let the KeyError surface
        allow(Temporal).to receive(:start_workflow).and_raise(KeyError.new("key not found: :workflow_params"))
      end

      it "handles the error and returns failure response" do
        result = workflow.execute(sync_run_id: sync_run_id, workflow_params: invalid_params)

        expect(logger).to have_received(:error).with("Invalid workflow_params structure: key not found: :workflow_params")
        expect(result).to eq({
                               workflow_id: workflow_id,
                               error: "Invalid workflow parameters",
                               success: false
                             })
      end
    end

    context "when an unexpected error occurs" do
      let(:error_message) { "Something went wrong" }

      before do
        allow(Temporal).to receive(:start_workflow)
          .and_raise(StandardError.new(error_message))
        allow(logger).to receive(:error)
      end

      it "handles the error and returns failure response" do
        result = workflow.execute(sync_run_id: sync_run_id, workflow_params: workflow_params)

        expect(logger).to have_received(:error).with("Failed to start workflow: #{error_message}")
        expect(result).to eq({
                               workflow_id: workflow_id,
                               error: error_message,
                               success: false
                             })
      end
    end
  end
end
