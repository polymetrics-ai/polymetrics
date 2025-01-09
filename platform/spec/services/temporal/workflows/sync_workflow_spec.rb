# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::SyncWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata", parent_id: "parent-workflow-id", parent_run_id: "parent-run-id") }
  let(:workflow_context) { instance_double("WorkflowContext", logger: double("Logger"), metadata: workflow_metadata) }

  let(:organization) { create(:organization) }
  let(:workspace) { create(:workspace, organization: organization) }
  let(:source) { create(:connector, workspace: workspace, integration_type: "api") }
  let(:destination) { create(:connector, workspace: workspace, integration_type: "database") }
  let(:connection) { create(:connection, source: source, destination: destination, workspace: workspace) }
  let(:sync) { create(:sync, connection: connection, stream_name: "test_stream") }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:sync_run_id) { sync_run.id }
  let(:redis) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")) }

  before do
    redis.flushdb

    # Mock basic workflow context
    allow(workflow).to receive(:workflow).and_return(
      instance_double("Workflow",
                      metadata: workflow_metadata,
                      execute!: true)
    )

    # Mock model relationships
    allow(SyncRun).to receive(:find).with(sync_run_id).and_return(sync_run)
    allow(sync_run).to receive(:sync).and_return(sync)
    allow(sync).to receive(:connection).and_return(connection)
    allow(connection).to receive_messages(source: source, destination: destination)
    allow(sync).to receive(:error!)

    # Mock activities
    allow(Temporal::Activities::UpdateSyncStatusActivity).to receive(:execute!)
    allow(Temporal::Activities::LogSyncErrorActivity).to receive(:execute!)
    allow(Temporal::Activities::TransformRecordActivity).to receive(:execute!)
      .with(sync_run_id).and_return({ success: true })
    allow(Temporal::Activities::ConvertReadRecordActivity).to receive(:execute!)
      .with(sync_run_id).and_return({ success: true })

    # Add this mock for Temporal.signal_workflow
    allow(Temporal).to receive(:signal_workflow)
      .with(
        "Temporal::Workflows::ConnectionDataSyncWorkflow",
        "sync_workflow_completed",
        "parent-workflow-id",
        "parent-run-id",
        hash_including(sync_run_id: sync_run_id)
      )

    # Add workflow context mock for ApiDataExtractorWorkflow
    allow(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow).to receive(:execute!)
      .with(
        sync_run_id,
        options: { workflow_id: "api_data_extractor-sync_id_#{sync.id}" }
      ).and_return({ success: true })

    # Mock the workflow execution context
    allow_any_instance_of(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow)
      .to receive(:workflow)
      .and_return(instance_double("Workflow", execute!: true))
  end

  after { redis.flushdb }

  describe "#execute" do
    context "when execution is successful" do
      before do
        allow(source).to receive(:integration_type).and_return("api")
        allow(destination).to receive(:integration_type).and_return("database")

        # Mock API extraction with correct workflow ID
        allow(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow).to receive(:execute!)
          .with(
            sync_run_id,
            options: { workflow_id: "api_data_extractor-sync_id_#{sync.id}" }
          ).and_return({ success: true })

        # Mock database loading with correct workflow ID
        allow(Temporal::Workflows::Loaders::DatabaseDataLoaderWorkflow).to receive(:execute!)
          .with(
            sync_run_id,
            options: { workflow_id: "database_loader_#{sync_run_id}" }
          ).and_return({ success: true })

        allow(Temporal).to receive(:signal_workflow)
      end

      it "executes the sync process successfully" do
        result = workflow.execute(sync_run_id)

        expect(result).to eq({
                               success: true,
                               status: "completed"
                             })

        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "syncing").ordered
        expect(Temporal::Activities::UpdateSyncStatusActivity).to have_received(:execute!)
          .with(sync_run_id: sync_run_id, status: "synced").ordered
      end

      it "signals completion to parent workflow" do
        workflow.execute(sync_run_id)

        expect(Temporal).to have_received(:signal_workflow).with(
          "Temporal::Workflows::ConnectionDataSyncWorkflow",
          "sync_workflow_completed",
          "parent-workflow-id",
          "parent-run-id",
          {
            sync_run_id: sync_run_id,
            success: "completed"
          }
        )
      end
    end

    context "when extraction fails" do
      before do
        allow(source).to receive(:integration_type).and_return("api")
        allow(destination).to receive(:integration_type).and_return("database")

        allow(Temporal::Workflows::Extractors::ApiDataExtractorWorkflow).to receive(:execute!)
          .with(
            sync_run_id,
            options: { workflow_id: "api_data_extractor-sync_id_#{sync.id}" }
          ).and_return({ success: false, error: "Extraction failed" })
      end

      it "handles the error appropriately" do
        result = workflow.execute(sync_run_id)

        expect(result).to eq({
                               success: false,
                               status: "error",
                               error: "Extraction failed"
                             })
      end
    end

    context "with unsupported integration types" do
      context "with unsupported source type" do
        before do
          allow(source).to receive(:integration_type).and_return("unsupported")
          allow(destination).to receive(:integration_type).and_return("database")
        end

        it "returns error for unsupported source type" do
          result = workflow.execute(sync_run_id)

          expect(result).to eq({
                                 success: false,
                                 status: "error",
                                 error: "Unsupported source integration type: unsupported"
                               })
        end
      end

      context "with unsupported destination type" do
        before do
          allow(source).to receive(:integration_type).and_return("api")
          allow(destination).to receive(:integration_type).and_return("api")
        end

        it "returns error for unsupported destination type" do
          result = workflow.execute(sync_run_id)

          expect(result).to eq({
                                 success: false,
                                 status: "error",
                                 error: "API data loading not yet supported"
                               })
        end
      end
    end

    context "when API data loading is attempted" do
      before do
        allow(source).to receive(:integration_type).and_return("api")
        allow(destination).to receive(:integration_type).and_return("api")
      end

      it "returns error for unsupported API loading" do
        result = workflow.execute(sync_run_id)

        expect(result).to eq({
                               success: false,
                               status: "error",
                               error: "API data loading not yet supported"
                             })
      end
    end
  end
end
