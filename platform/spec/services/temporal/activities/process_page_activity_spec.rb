# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::ProcessPageActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger, heartbeat: nil) }
  let(:logger) { instance_double("Logger", info: nil, error: nil) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync, total_pages: 5) }
  let(:workflow_store) { instance_double(WorkflowStoreService) }
  let(:workflow_id) { "test_workflow_123" }
  let(:pages) { [2] }
  let(:page_data) { [{ "id" => 1, "name" => "Test" }, { "id" => 2, "name" => "Test 2" }] }
  let(:workflow_data) do
    {
      result: {
        data: page_data
      }
    }
  end
  let(:signal_data) do
    {
      workflow_id: workflow_id
    }
  end

  before do
    allow(WorkflowStoreService).to receive(:new).and_return(workflow_store)
    allow(workflow_store).to receive(:get_workflow_data)
      .with("#{workflow_id}:2")
      .and_return(workflow_data)
    allow(logger).to receive(:error).with(any_args)
  end

  describe "#execute" do
    context "when successful" do
      it "returns success response" do
        result = subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data,
          pages: pages
        )

        expect(result).to eq({
                               status: "success",
                               processed_pages: pages,
                               batch_id: nil
                             })
      end

      it "creates sync read record" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: signal_data,
            pages: pages
          )
        end.to change(SyncReadRecord, :count).by(1)

        record = SyncReadRecord.last
        expect(record.data).to eq(page_data)
        expect(record.sync_run).to eq(sync_run)
        expect(record.sync).to eq(sync)
      end

      it "updates sync run statistics" do
        subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data,
          pages: pages
        )

        sync_run.reload
        expect(sync_run.attributes).to include(
          "current_page" => pages[0],
          "total_records_read" => 2,
          "successful_records_read" => 2
        )
        expect(sync_run.last_extracted_at).to be_present
      end
    end

    context "when sync run not found" do
      it "raises RecordNotFound" do
        expect do
          subject.execute(
            sync_run_id: -1,
            signal_data: signal_data,
            pages: pages
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with duplicate records" do
      before do
        create(:sync_read_record,
               sync: sync,
               sync_run: sync_run,
               data: page_data)
      end

      it "logs and handles duplicates" do
        expect(context.logger).to receive(:info)
          .with("Skipping duplicate page for sync_id: #{sync.id}")

        result = subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data,
          pages: pages
        )

        expect(result[:status]).to eq("success")
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
