# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::LogSyncErrorActivity do
  let(:activity) { described_class.new(double("context")) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:error_message) { "Test error message" }

  describe "#execute" do
    context "when sync_run_id is provided" do
      it "creates a sync log with error type" do
        expect do
          activity.execute(
            sync_run_id: sync_run.id,
            sync_id: sync.id,
            error_message: error_message
          )
        end.to change(SyncLog, :count).by(1)

        log = SyncLog.last
        expect(log.log_type).to eq("error")
        expect(log.message).to eq(error_message)
        expect(log.emitted_at).to be_present
      end

      it "logs error message to Rails logger" do
        expect(Rails.logger).to receive(:error)
          .with("Sync #{sync.id} failed: #{error_message}")

        activity.execute(
          sync_run_id: sync_run.id,
          sync_id: sync.id,
          error_message: error_message
        )
      end
    end

    context "when sync_run_id is not provided" do
      it "only logs to Rails logger without creating sync log" do
        expect(Rails.logger).to receive(:error)
          .with("Sync #{sync.id} failed: #{error_message}")

        expect do
          activity.execute(
            sync_run_id: nil,
            sync_id: sync.id,
            error_message: error_message
          )
        end.not_to change(SyncLog, :count)
      end
    end

    context "when sync_run is not found" do
      it "raises RecordNotFound error" do
        expect do
          activity.execute(
            sync_run_id: -1,
            sync_id: sync.id,
            error_message: error_message
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
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
