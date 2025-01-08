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
  let(:sync_read_record_data) { [{ "id" => 1, "name" => "Test" }] }
  let(:redis) { Redis.new(url: "redis://localhost:6379/1") }
  let(:mock_incremental_service) { instance_double(Etl::Extractors::ConvertReadRecord::IncrementalDedupService, call: true) }

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
      let!(:sync_read_record) do
        create(:sync_read_record, sync: sync, sync_run: sync_run, data: sync_read_record_data,
                                  extraction_completed_at: Time.current)
      end

      before do
        sync_run.update!(extraction_completed: true, total_records_read: 1)

        # Store transformed data in Redis
        redis_key = "sync:#{sync.id}:transformed:#{sync_read_record.id}"
        redis.set(redis_key, sync_read_record_data.to_json)
      end

      after do
        redis.flushdb
      end

      it "processes records and updates sync_run status" do
        result = activity.execute(sync_run.id)

        expect(result[:success]).to be true
        expect(result[:transformation_completed]).to be true
      end

      it "creates write records for each data entry" do
        expect { activity.execute(sync_run.id) }
          .to change(SyncWriteRecord, :count).by(1)
      end

      it "marks read record as processed" do
        activity.execute(sync_run.id)
        expect(sync_read_record.reload.extraction_completed_at).to be_present
      end
    end

    context "when some records fail to process" do
      before do
        sync_run.update!(extraction_completed: true, total_records_read: 2)

        # Create valid record and store its transformed data in Redis
        valid_record = create(:sync_read_record,
                              sync: sync,
                              sync_run: sync_run,
                              data: sync_read_record_data,
                              extraction_completed_at: Time.current)

        redis_key = "sync:#{sync.id}:transformed:#{valid_record.id}"
        redis.set(redis_key, sync_read_record_data.to_json)

        # Create invalid record that will fail
        invalid_record = create(:sync_read_record,
                                sync: sync,
                                sync_run: sync_run,
                                data: "invalid",
                                extraction_completed_at: Time.current)

        invalid_record_key = "sync:#{sync.id}:transformed:#{invalid_record.id}"
        redis.set(invalid_record_key, invalid_record.data.to_json)
      end

      after do
        redis.flushdb
      end

      it "returns partial success with warnings" do
        result = activity.execute(sync_run.id)

        expect(result[:success]).to be true
        expect(result[:warning]).to include("1 out of 2 records failed to convert")
        expect(result[:failed_records]).to be_present
      end
    end
  end

  describe "#create_write_records" do
    context "with invalid data format" do
      let!(:sync_read_record) { create(:sync_read_record, sync: sync, sync_run: sync_run, data: "invalid") }

      it "logs error and skips record creation" do
        expect(Rails.logger).to receive(:error).with("Invalid data format for sync_read_record #{sync_read_record.id}")

        expect do
          activity.send(:create_write_records, sync_read_record)
        end.not_to change(SyncWriteRecord, :count)
      end
    end

    context "with empty data" do
      let!(:sync_read_record) do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: [{ "test" => "initial" }])
      end

      before do
        sync_read_record.update_column(:data, "[]")
      end

      it "skips record creation" do
        expect do
          activity.send(:create_write_records, sync_read_record)
        end.not_to change(SyncWriteRecord, :count)
      end
    end

    context "with valid array data" do
      let!(:sync_read_record) do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: [{ "key1" => "value1" }, { "key2" => "value2" }])
      end

      it "creates write records for each data entry" do
        expect do
          activity.send(:create_write_records, sync_read_record)
        end.to change(SyncWriteRecord, :count).by(2)
      end

      it "creates write records with correct associations" do
        activity.send(:create_write_records, sync_read_record)

        write_record = SyncWriteRecord.last
        expect(write_record.sync).to eq(sync)
        expect(write_record.sync_run).to eq(sync_run)
        expect(write_record.sync_read_record).to eq(sync_read_record)
        expect(write_record.data).to be_present
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
end
