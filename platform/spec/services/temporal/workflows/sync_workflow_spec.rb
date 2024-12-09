# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::SyncWorkflow do
  let(:workflow) { described_class.new(instance_double("WorkflowContext", logger: double("Logger"))) }
  let(:sync_run_id) { 123 }
  let(:sync) { instance_double("Sync", id: 456, connection: connection) }
  let(:sync_run) { instance_double("SyncRun", id: sync_run_id, sync: sync, sync_id: sync.id) }
  let(:connection) { instance_double("Connection", source: source) }
  let(:source) { instance_double("Source", integration_type: integration_type) }
  let(:integration_type) { "api" }

  before do
    allow(SyncRun).to receive(:find).with(sync_run_id).and_return(sync_run)
    allow(sync).to receive(:synced!)
    allow(sync).to receive(:error!)

    # Stub activities
    allow(Temporal::Activities::UpdateSyncStatusActivity).to receive(:execute!)
    allow(Temporal::Activities::LogSyncErrorActivity).to receive(:execute!)
    allow(Temporal::Activities::ConvertReadRecordActivity).to receive(:execute!)
  end

  describe "#execute" do
    context "when execution is successful" do
      before do
        allow(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow).to receive(:execute!)
          .and_return({ success: true })
      end

      it "completes the sync process successfully" do
        workflow.execute(sync_run_id)

        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "syncing").once
        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "synced").once
        expect(sync).to have_received(:synced!)
      end
    end

    context "when integration type is unsupported" do
      let(:integration_type) { "unsupported_type" }
      let(:error_message) { "Unsupported integration type: #{integration_type}" }

      it "handles the error appropriately" do
        workflow.execute(sync_run_id)

        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "syncing").once
        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "error").once
        expect(Temporal::Activities::LogSyncErrorActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, sync_id: sync.id, error_message: error_message)
        expect(sync).to have_received(:error!)
      end
    end

    context "when extraction fails" do
      shared_examples "handles extraction failure" do |scenario, expected_error|
        before do
          allow(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow)
            .to receive(:execute!).and_return(failure_result)
        end

        it "handles #{scenario} appropriately" do
          workflow.execute(sync_run_id)

          expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
            .with(sync_run_id: sync_run_id, status: "syncing").once
          expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
            .with(sync_run_id: sync_run_id, status: "error").once
          expect(Temporal::Activities::LogSyncErrorActivity).to have_received(:execute!)
            .with(sync_run_id: sync_run_id, sync_id: sync.id, error_message: expected_error)
          expect(sync).to have_received(:error!)
        end
      end

      context "with nil result" do
        let(:failure_result) { nil }

        include_examples "handles extraction failure",
                         "nil result",
                         "Extraction result is nil"
      end

      context "with invalid format" do
        let(:failure_result) { "invalid" }

        include_examples "handles extraction failure",
                         "invalid format",
                         "Invalid extraction result format"
      end
    end
  end
end
