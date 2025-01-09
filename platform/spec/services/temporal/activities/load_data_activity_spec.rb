# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::LoadDataActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:activity) { described_class.new(activity_context) }
  let(:workflow_store) { instance_double(WorkflowStoreService) }

  # Setup connection hierarchy
  let(:destination) { create(:connector, integration_type: "database", connector_language: "ruby") }
  let(:connection) { create(:connection, destination: destination) }
  let(:sync) { create(:sync, connection: connection) }
  let(:sync_run) { create(:sync_run, sync: sync) }

  let(:database_data_loader_workflow_id) { "test_workflow_123" }
  let(:database_data_loader_workflow_run_id) { "test_run_456" }

  before do
    allow(WorkflowStoreService).to receive(:new).and_return(workflow_store)
    allow(workflow_store).to receive(:store_workflow_data)
  end

  describe "#execute" do
    context "when successful" do
      let(:write_records) do
        create_list(:sync_write_record, 3,
                    sync: sync,
                    sync_run: sync_run,
                    status: :pending,
                    data: { "id" => 1, "name" => "Test" })
      end

      before do
        allow(Temporal).to receive(:start_workflow)
        write_records
      end

      it "processes records and starts write workflow" do
        result = activity.execute(
          sync_run.id,
          database_data_loader_workflow_id,
          database_data_loader_workflow_run_id
        )

        expect(result).to eq({ success: true })
      end

      it "stores batch data in workflow store" do
        activity.execute(
          sync_run.id,
          database_data_loader_workflow_id,
          database_data_loader_workflow_run_id
        )

        expect(workflow_store).to have_received(:store_workflow_data)
          .with("write_data_#{sync_run.id}:1", kind_of(Hash))
      end

      it "starts write workflow with correct parameters" do
        activity.execute(
          sync_run.id,
          database_data_loader_workflow_id,
          database_data_loader_workflow_run_id
        )

        expect(Temporal).to have_received(:start_workflow).with(
          "RubyConnectors::Temporal::Workflows::WriteDatabaseDataWorkflow",
          hash_including(
            workflow_id: "write_data_#{sync_run.id}",
            total_batches: 1,
            batch_size: described_class::BATCH_SIZE,
            sync_run_id: sync_run.id,
            database_data_loader_workflow_id: database_data_loader_workflow_id,
            database_data_loader_workflow_run_id: database_data_loader_workflow_run_id
          ),
          {
            options: hash_including(
              workflow_id: "write_data_#{sync_run.id}",
              task_queue: "ruby_connectors_queue"
            )
          }
        )
      end
    end

    context "when error occurs during processing" do
      let(:write_records) do
        create_list(:sync_write_record, 3,
                    sync: sync,
                    sync_run: sync_run,
                    status: :pending,
                    data: { "id" => 1, "name" => "Test" })
      end

      before do
        allow(workflow_store).to receive(:store_workflow_data)
          .and_raise(StandardError.new("Storage error"))
        write_records
      end

      it "returns error status with message" do
        result = activity.execute(
          sync_run.id,
          database_data_loader_workflow_id,
          database_data_loader_workflow_run_id
        )

        expect(result).to eq({
                               success: false,
                               error: "Storage error"
                             })
      end
    end
  end

  describe "activity configuration" do
    it "has correct retry policy" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy).to include(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )
    end

    it "has correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts).to include(
        start_to_close: 600,
        heartbeat: 120,
        schedule_to_close: 1800
      )
    end
  end

  describe "queue determination" do
    context "with different connector languages" do
      let(:destination) { create(:connector, connector_language: connector_language) }
      let(:connection) { create(:connection, destination: destination) }
      let(:sync) { create(:sync, connection: connection) }
      let(:sync_run) { create(:sync_run, sync: sync) }

      before do
        activity.instance_variable_set(:@sync, sync)
      end

      context "with ruby connector" do
        let(:connector_language) { "ruby" }

        it "returns ruby queue" do
          expect(activity.send(:determine_task_queue))
            .to eq(described_class::LANGUAGE_CONNECTOR_QUEUES[:ruby])
        end
      end

      context "with python connector" do
        let(:connector_language) { "python" }

        it "returns python queue" do
          expect(activity.send(:determine_task_queue))
            .to eq(described_class::LANGUAGE_CONNECTOR_QUEUES[:python])
        end
      end

      context "with javascript connector" do
        let(:connector_language) { "javascript" }

        it "returns javascript queue" do
          expect(activity.send(:determine_task_queue))
            .to eq(described_class::LANGUAGE_CONNECTOR_QUEUES[:javascript])
        end
      end
    end
  end
end
