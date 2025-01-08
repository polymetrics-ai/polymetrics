# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::UpdateSyncStatusActivity do
  subject(:activity) { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", error: nil, info: nil, warn: nil) }
  let(:sync_run) { create(:sync_run) }
  let(:sync) { sync_run.sync }

  describe "#execute" do
    context "when successful" do
      it "updates sync status and creates log" do
        result = activity.execute(
          sync_run_id: sync_run.id,
          status: "syncing",
          error_message: nil
        )

        expect(result).to include(
          status: "syncing",
          updated_at: be_within(1.second).of(Time.current),
          sync_id: sync.id
        )
      end

      it "logs status change" do
        old_status = sync.status

        expect(logger).to receive(:info).with(
          "Sync status updated from #{old_status} to syncing: Started syncing"
        )

        activity.execute(
          sync_run_id: sync_run.id,
          status: "syncing"
        )
      end

      it "creates a sync log entry" do
        expect do
          activity.execute(
            sync_run_id: sync_run.id,
            status: "syncing"
          )
        end.to change(SyncLog, :count).by(1)

        log = SyncLog.last
        expect(log.message).to eq("Started syncing")
        expect(log.log_type).to eq("info")
      end
    end

    context "with different status types" do
      it "handles synced status" do
        result = activity.execute(
          sync_run_id: sync_run.id,
          status: "synced"
        )

        expect(result[:status]).to eq("synced")
        expect(SyncLog.last.message).to eq("Successfully completed sync")
      end

      it "handles error status with message" do
        result = activity.execute(
          sync_run_id: sync_run.id,
          status: "error",
          error_message: "Connection failed"
        )

        expect(result[:status]).to eq("error")
        expect(SyncLog.last.message).to eq("Failed with error: Connection failed")
      end

      it "handles action_required status" do
        result = activity.execute(
          sync_run_id: sync_run.id,
          status: "action_required"
        )

        expect(result[:status]).to eq("action_required")
        expect(SyncLog.last.message).to eq("Action required for sync")
      end
    end

    context "when sync_run is not found" do
      it "raises RecordNotFound error" do
        expect do
          activity.execute(
            sync_run_id: -1,
            status: "syncing"
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "logs the error" do
        expect(logger).to receive(:error).with(
          "Failed to update sync status for sync run -1 error: Couldn't find SyncRun with 'id'=-1"
        )

        expect do
          activity.execute(
            sync_run_id: -1,
            status: "syncing"
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with invalid status" do
      it "raises ArgumentError" do
        expect do
          activity.execute(
            sync_run_id: sync_run.id,
            status: "invalid_status"
          )
        end.to raise_error(ArgumentError, "Invalid sync status: invalid_status")
      end
    end
  end

  describe "retry policy" do
    it "configures correct retry settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy).to include(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )
    end
  end
end
