# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::ConnectionDataSyncWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_context) { instance_double("WorkflowContext", on_signal: true, wait_until: true) }

  let(:connection) { instance_double(Connection, id: 1, status: "completed") }
  let(:sync_run_ids) { [1, 2] }
  let(:sync_runs) do
    sync_run_ids.map do |id|
      instance_double(SyncRun, id: id, update: true)
    end
  end

  before do
    allow(workflow).to receive(:workflow).and_return(workflow_context)
    allow(Connection).to receive(:find).with(connection.id).and_return(connection)
    allow(SyncRun).to receive(:find).and_return(*sync_runs)
  end

  describe "#execute" do
    context "when execution is successful" do
      before do
        allow(Temporal::Activities::PrepareSyncRunsActivity).to receive(:execute!)
          .with(connection_id: connection.id)
          .and_return(sync_run_ids)

        allow(Temporal).to receive(:start_workflow)
          .and_return("workflow_run_id")

        allow(Temporal::Activities::UpdateConnectionStatusActivity).to receive(:execute!)
      end

      it "prepares sync runs and starts child workflows" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::PrepareSyncRunsActivity).to have_received(:execute!)
          .with(connection_id: connection.id)
      end

      it "starts child workflows for each sync run" do
        workflow.execute(connection.id)

        sync_runs.each do |sync_run|
          expect(Temporal).to have_received(:start_workflow).with(
            Temporal::Workflows::SyncWorkflow,
            sync_run.id,
            options: {
              workflow_id: "sync_run_#{sync_run.id}",
              task_queue: "platform_queue"
            }
          )
        end
      end

      it "updates connection status to completed" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::UpdateConnectionStatusActivity).to have_received(:execute!)
          .with(connection_id: connection.id, status: :completed)
      end
    end

    context "when an error occurs" do
      let(:error_message) { "Something went wrong" }

      before do
        allow(Temporal::Activities::PrepareSyncRunsActivity).to receive(:execute!)
          .and_raise(StandardError.new(error_message))

        allow(Temporal::Activities::UpdateConnectionStatusActivity).to receive(:execute!)
        allow(Temporal::Activities::LogConnectionErrorActivity).to receive(:execute!)
      end

      it "updates connection status to failed and logs the error" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::UpdateConnectionStatusActivity).to have_received(:execute!)
          .with(connection_id: connection.id, status: :failed)

        expect(Temporal::Activities::LogConnectionErrorActivity).to have_received(:execute!)
          .with(connection_id: connection.id, error_message: error_message)
      end
    end
  end
end
