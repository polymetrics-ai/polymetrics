# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::UpdateWriteCompletionActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:activity) { described_class.new(activity_context) }

  let(:destination) { create(:connector, integration_type: "database") }
  let(:connection) { create(:connection, destination: destination) }
  let(:sync) { create(:sync, connection: connection) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:write_records) do
    create_list(:sync_write_record, 3,
                sync: sync,
                sync_run: sync_run,
                status: :pending)
  end

  describe "#execute" do
    context "when successful" do
      it "updates write records status" do
        activity.execute(
          sync_run_id: sync_run.id,
          write_record_ids: write_records.map(&:id)
        )

        write_records.each do |record|
          expect(record.reload.status).to eq("written")
        end
      end

      it "updates sync run statistics" do
        expect do
          activity.execute(
            sync_run_id: sync_run.id,
            write_record_ids: write_records.map(&:id)
          )
        end.to change { sync_run.reload.successful_records_write }.by(write_records.size)
      end
    end

    context "when sync run not found" do
      it "raises RecordNotFound error" do
        expect do
          activity.execute(
            sync_run_id: -1,
            write_record_ids: write_records.map(&:id)
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when error occurs" do
      before do
        allow(SyncRun).to receive(:find).and_raise(StandardError.new("Database error"))
      end

      it "logs error and re-raises" do
        expect(logger).to receive(:error).with("Failed to update write completion: Database error")

        expect do
          activity.execute(
            sync_run_id: sync_run.id,
            write_record_ids: write_records.map(&:id)
          )
        end.to raise_error(StandardError, "Database error")
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
        start_to_close: 60,
        heartbeat: 20,
        schedule_to_close: 120
      )
    end
  end
end
