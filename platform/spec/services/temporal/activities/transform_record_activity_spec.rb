# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::TransformRecordActivity do
  let(:context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil, info: nil) }
  let(:activity) { described_class.new(context) }
  let(:sync) { create(:sync, destination_database_schema: schema) }
  let(:sync_run) { create(:sync_run, sync: sync, total_records_read: 1, extraction_completed: true) }
  let(:redis) { Redis.new(url: "redis://localhost:6379/1") }
  let(:schema) do
    {
      "mapping" => [
        { "from" => "source_field", "to" => "dest_field" },
        { "from" => "name", "to" => "full_name" }
      ]
    }
  end

  after do
    redis.flushdb
  end

  describe "#execute" do
    context "when sync_run is not completed" do
      before do
        sync_run.update(extraction_completed: false)
      end

      it "returns error without processing records" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "Extraction already completed for sync run #{sync_run.id}"
                             })
      end
    end

    context "when sync_run has no read records" do
      it "returns error without processing records" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({
                               success: false,
                               error: "No records found to transform for sync run #{sync_run.id}"
                             })
      end
    end

    context "when processing records" do
      let(:record_data) { [{ "source_field" => "test_value", "name" => "John Doe" }] }
      let!(:sync_read_record) do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: record_data)
      end

      before do
        sync_run.update(extraction_completed: true)
      end

      it "transforms and stores records successfully" do
        result = activity.execute(sync_run.id)

        expect(result).to eq({ success: true })

        # Verify Redis storage
        redis_key = "sync:#{sync.id}:transformed:#{sync_read_record.id}"
        stored_data = JSON.parse(redis.get(redis_key))
        expect(stored_data).to eq([{
                                    "dest_field" => "test_value",
                                    "full_name" => "John Doe"
                                  }])
      end
    end

    context "when some records fail to transform" do
      let(:valid_data) { [{ "source_field" => "test_value", "name" => "John Doe" }] }
      let(:invalid_data) { "invalid_data" }

      before do
        sync_run.update(extraction_completed: true)
        create(:sync_read_record, sync: sync, sync_run: sync_run, data: valid_data)
        create(:sync_read_record, sync: sync, sync_run: sync_run, data: invalid_data)
        sync_run.update(total_records_read: 2)
      end

      it "returns partial success with warnings" do
        result = activity.execute(sync_run.id)

        expect(result[:success]).to be true
        expect(result[:warning]).to include("1 out of 2 records failed to transform")
        expect(result[:failed_records]).to be_present
      end
    end

    context "when all records fail to transform" do
      let(:invalid_data) { "invalid_data" }

      before do
        sync_run.update(extraction_completed: true)
        create(:sync_read_record, sync: sync, sync_run: sync_run, data: invalid_data)
        sync_run.update(total_records_read: 1)
      end

      it "returns failure with error message" do
        result = activity.execute(sync_run.id)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("All 1 records failed to transform")
        expect(result[:failed_records]).to be_present
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

  describe "timeouts" do
    it "has the correct timeout settings" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts[:start_to_close]).to eq(600)
      expect(timeouts[:heartbeat]).to eq(120)
      expect(timeouts[:schedule_to_close]).to eq(1800)
    end
  end
end
