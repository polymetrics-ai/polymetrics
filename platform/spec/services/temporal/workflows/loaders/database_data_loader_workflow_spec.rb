# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Loaders::DatabaseDataLoaderWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata", id: "test-workflow-id", run_id: "test-run-id") }
  let(:workflow_context) { instance_double("WorkflowContext", logger: double("Logger"), metadata: workflow_metadata) }
  let(:workflow_double) do
    double(
      "Workflow",
      metadata: workflow_metadata,
      on_signal: nil,
      wait_until: true,
      execute!: true
    )
  end

  let(:destination) { create(:connector, integration_type: "database") }
  let(:connection) { create(:connection, destination: destination) }
  let(:sync) { create(:sync, connection: connection) }
  let(:sync_run) { create(:sync_run, sync: sync) }

  before do
    # Mock workflow methods
    allow(workflow).to receive(:workflow).and_return(workflow_double)

    # Mock activities
    allow(Temporal::Activities::LoadDataActivity).to receive(:execute!)
    allow(Temporal::Activities::UpdateWriteCompletionActivity).to receive(:execute!)
    allow(Temporal::Activities::UpdateSyncStatusActivity).to receive(:execute!)
  end

  describe "#execute" do
    context "when successful" do
      before do
        allow(Temporal::Activities::LoadDataActivity).to receive(:execute!)
          .with(sync_run.id, "test-workflow-id", "test-run-id")
          .and_return({ success: true })

        # Simulate write completion signal
        allow(workflow_double).to receive(:on_signal)
          .with("database_write_completed")
          .and_yield({
                       status: "success",
                       workflow_id: "write-workflow-id",
                       total_batches: 3
                     })
      end

      it "executes the workflow successfully" do
        result = workflow.execute(sync_run.id)

        expect(result).to eq({
                               success: true,
                               message: "Database loading completed"
                             })
      end

      it "calls activities in correct order" do
        workflow.execute(sync_run.id)

        expect(Temporal::Activities::LoadDataActivity).to have_received(:execute!)
          .with(sync_run.id, "test-workflow-id", "test-run-id")
          .ordered

        expect(Temporal::Activities::UpdateWriteCompletionActivity).to have_received(:execute!)
          .with(
            sync_run_id: sync_run.id,
            workflow_id: "write-workflow-id",
            total_batches: 3
          )
          .ordered

        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(
            sync_run_id: sync_run.id,
            status: :synced
          )
          .ordered
      end
    end

    context "when load data activity fails" do
      before do
        allow(Temporal::Activities::LoadDataActivity).to receive(:execute!)
          .and_return({ success: false, error: "Loading failed" })
      end

      it "returns error result" do
        result = workflow.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "Failed to start loading: Loading failed"
                             })
      end

      it "does not process write completion" do
        workflow.execute(sync_run.id)

        expect(Temporal::Activities::UpdateWriteCompletionActivity)
          .not_to have_received(:execute!)
      end
    end
  end

  describe "workflow configuration" do
    it "has correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts).to include(
        execution: 86_400,
        run: 86_400,
        task: 10
      )
    end
  end
end
