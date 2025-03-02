# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::ConvertReadRecordActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil, info: nil) }
  let(:activity) { described_class.new(activity_context) }
  let(:destination) { create(:connector, integration_type: "database", connector_class_name: "database") }
  let(:connection) { create(:connection, destination: destination) }
  let(:sync) do
    create(:sync, connection: connection, supported_sync_modes: ["incremental_dedup"], sync_mode: "incremental_dedup",
                  source_defined_primary_key: ["id"])
  end
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:redis_key) { "sync:#{sync.id}:run:#{sync_run.id}:transformed" }
  let(:record_data) { [{ "id" => 1, "name" => "Test" }] }
  let(:mock_incremental_service) { instance_double(Etl::Extractors::ConvertReadRecord::IncrementalDedupService) }

  before do
    allow(Etl::Extractors::ConvertReadRecord::IncrementalDedupService).to receive(:new).and_return(mock_incremental_service)
    allow(mock_incremental_service).to receive(:call).and_return({ success: true, transformation_completed: true })
  end

  describe "#execute" do
    context "when extraction is not completed" do
      it "returns error without processing records" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "Extraction not completed for sync run #{sync_run.id}"
                             })
      end
    end

    context "when transformation is already completed" do
      before do
        sync_run.update!(
          extraction_completed: true,
          transformation_completed: true
        )
      end

      it "returns error without processing records" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "Transformation already completed for sync run #{sync_run.id}"
                             })
      end
    end

    context "when sync_run has no read records" do
      before do
        sync_run.update!(extraction_completed: true)
      end

      it "returns error without processing records" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "No records found to convert for sync run #{sync_run.id}"
                             })
      end
    end

    context "when sync_run has read records to process" do
      let(:sync_read_record) do
        create(:sync_read_record, sync: sync, sync_run: sync_run, data: { "original" => "data" },
                                  extraction_completed_at: Time.current)
      end

      before do
        sync_read_record
        sync_run.update!(extraction_completed: true, total_records_read: 1)
      end

      it "initializes the incremental dedup service with correct parameters" do
        expect(Etl::Extractors::ConvertReadRecord::IncrementalDedupService).to receive(:new)
          .with(sync_run, activity_context)
          .and_return(mock_incremental_service)

        activity.execute(sync_run.id)
      end

      it "calls the incremental dedup service" do
        expect(mock_incremental_service).to receive(:call)

        activity.execute(sync_run.id)
      end

      it "returns the result from the incremental dedup service" do
        service_result = {
          success: true,
          transformation_completed: true,
          custom_field: "test value"
        }

        allow(mock_incremental_service).to receive(:call).and_return(service_result)

        result = activity.execute(sync_run.id)
        expect(result).to eq(service_result)
      end
    end

    context "when an error occurs during processing" do
      let(:sync_read_record) do
        create(:sync_read_record, sync: sync, sync_run: sync_run,
                                  extraction_completed_at: Time.current)
      end

      before do
        sync_read_record
        sync_run.update!(extraction_completed: true, total_records_read: 1)
        allow(mock_incremental_service).to receive(:call).and_raise(StandardError.new("Test error"))
      end

      it "logs the error and returns a failure result" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to convert records for sync run #{sync_run.id}: Test error")
        end

        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "Test error"
                             })
      end
    end

    context "with a non-incremental sync" do
      let(:sync) do
        create(:sync, connection: connection,
                      supported_sync_modes: ["incremental_append"],
                      sync_mode: "incremental_append",
                      source_defined_primary_key: ["id"])
      end

      let(:sync_read_record) do
        create(:sync_read_record, sync: sync, sync_run: sync_run,
                                  extraction_completed_at: Time.current)
      end

      before do
        sync_read_record
        sync_run.update!(extraction_completed: true, total_records_read: 1)
      end

      it "raises a NotImplementedError" do
        expect do
          activity.execute(sync_run.id)
        end.to raise_error(NotImplementedError, /Non-incremental dedup sync processing is not supported/)
      end
    end
  end

  describe "retry policy" do
    it "has the correct retry policy settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy[:interval]).to eq(1)
      expect(retry_policy[:backoff]).to eq(1)
      expect(retry_policy[:max_attempts]).to eq(3)
    end
  end

  describe "timeout settings" do
    it "has the correct timeout settings" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts[:start_to_close]).to eq(3600)
    end
  end
end
