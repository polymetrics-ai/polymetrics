# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::PrepareSyncRunsActivity do
  let(:activity) { described_class.new(double("context")) }
  let(:connection) { create(:connection) }
  let(:sync1) { create(:sync, connection: connection) }
  let(:sync2) { create(:sync, connection: connection) }

  describe "#execute" do
    context "when connection exists" do
      before do
        sync1
        sync2
      end

      it "creates sync runs for all syncs in the connection" do
        expect do
          activity.execute(connection_id: connection.id)
        end.to change(SyncRun, :count).by(2)
      end

      it "returns an array of sync run ids" do
        result = activity.execute(connection_id: connection.id)

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result).to all(be_a(Integer))
      end

      it "creates sync runs with correct initial attributes" do
        activity.execute(connection_id: connection.id)

        sync_run = SyncRun.last
        aggregate_failures do
          expect(sync_run.status).to eq("running")
          expect(sync_run.started_at).to be_present
          expect(sync_run.total_records_read).to eq(0)
          expect(sync_run.total_records_written).to eq(0)
          expect(sync_run.successful_records_read).to eq(0)
          expect(sync_run.failed_records_read).to eq(0)
          expect(sync_run.successful_records_write).to eq(0)
          expect(sync_run.records_failed_to_write).to eq(0)
        end
      end
    end

    context "when connection does not exist" do
      it "raises RecordNotFound error" do
        expect do
          activity.execute(connection_id: -1)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when connection has no syncs" do
      it "returns an empty array" do
        result = activity.execute(connection_id: connection.id)
        expect(result).to eq([])
      end
    end
  end

  describe "retry policy" do
    it "has the correct retry policy settings" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy[:interval]).to eq(1)
      expect(retry_policy[:backoff]).to eq(2)
      expect(retry_policy[:max_attempts]).to eq(3)
    end
  end
end
