# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Workflows::WriteDatabaseDataWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata", id: "test-workflow-id", run_id: "test-run-id") }
  let(:workflow_context) { instance_double("WorkflowContext", logger: double("Logger"), metadata: workflow_metadata) }
  let(:workflow_double) { instance_double("Workflow", metadata: workflow_metadata) }

  let(:params) do
    {
      workflow_id: "test_workflow_123",
      total_batches: 2,
      database_data_loader_workflow_id: "loader_workflow_123",
      database_data_loader_workflow_run_id: "loader_run_456",
      connector_class_name: "duckdb",
      configuration: { database: "test_db" }
    }
  end

  before do
    allow(workflow).to receive(:workflow).and_return(workflow_double)
    allow(::Temporal).to receive(:signal_workflow)
  end

  describe "#execute" do
    context "when write is successful" do
      let(:activity_result) do
        {
          "status" => "success",
          "records_written" => 10
        }
      end

      before do
        allow(RubyConnectors::Temporal::Activities::WriteDatabaseDataActivity)
          .to receive(:execute!)
          .with(hash_including(params.transform_keys(&:to_s)))
          .and_return(activity_result)
      end

      it "returns success result with records written" do
        result = workflow.execute(params)

        expect(result).to eq({
          status: "success",
          records_written: 10,
          error: nil
        })
      end

      it "signals completion to parent workflow" do
        workflow.execute(params)

        expect(::Temporal).to have_received(:signal_workflow).with(
          "Temporal::Workflows::Loaders::DatabaseDataLoaderWorkflow",
          "database_write_completed",
          params[:database_data_loader_workflow_id],
          params[:database_data_loader_workflow_run_id],
          {
            status: "success",
            workflow_id: params[:workflow_id],
            total_batches: params[:total_batches]
          }
        )
      end
    end

    context "when write fails" do
      let(:error_message) { "Write operation failed" }
      let(:activity_result) do
        {
          status: "error",
          records_written: 0,
          error: error_message
        }
      end

      before do
        allow(RubyConnectors::Temporal::Activities::WriteDatabaseDataActivity)
          .to receive(:execute!)
          .and_return(activity_result)
      end

      it "returns error result" do
        result = workflow.execute(params)

        expect(result).to eq({
          status: "error",
          records_written: 0,
          error: error_message
        })
      end

      it "does not signal completion" do
        workflow.execute(params)

        expect(::Temporal).not_to have_received(:signal_workflow)
      end
    end

    context "when activity raises an error" do
      let(:error_message) { "Unexpected error" }

      before do
        allow(RubyConnectors::Temporal::Activities::WriteDatabaseDataActivity)
          .to receive(:execute!)
          .and_raise(StandardError.new(error_message))
      end

      it "returns error result" do
        result = workflow.execute(params)

        expect(result).to eq({
          status: "error",
          records_written: 0,
          error: error_message
        })
      end

      it "does not signal completion" do
        workflow.execute(params)

        expect(::Temporal).not_to have_received(:signal_workflow)
      end
    end
  end
end 