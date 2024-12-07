# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::ProcessFirstPageActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", info: nil) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:workflow_store) { instance_double(WorkflowStoreService) }
  let(:workflow_id) { "test_workflow_123" }
  let(:page_data) { [{ "id" => 1, "name" => "Test" }] }
  let(:workflow_data) do
    {
      result: {
        data: page_data
      }
    }
  end
  let(:signal_data) do
    {
      workflow_id: workflow_id,
      total_pages: 3
    }
  end

  before do
    allow(WorkflowStoreService).to receive(:new).and_return(workflow_store)
    allow(workflow_store).to receive(:get_workflow_data)
      .with("#{workflow_id}:1")
      .and_return(workflow_data)
  end

  describe ".execute_in_context" do
    let(:input) do
      [{
        sync_run_id: sync_run.id,
        signal_data: signal_data
      }]
    end

    it "executes activity with correct context" do
      expect(described_class)
        .to receive(:new)
        .with(context)
        .and_return(subject)

      expect(subject)
        .to receive(:execute)
        .with(sync_run_id: sync_run.id, signal_data: signal_data)

      described_class.execute_in_context(context, input)
    end
  end

  describe "#execute" do
    context "when successful" do
      it "returns success response" do
        result = subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data
        )

        expect(result).to eq({
                               status: "success",
                               message: "first page processed",
                               total_pages: 3
                             })
      end

      it "creates sync read record" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: signal_data
          )
        end.to change(SyncReadRecord, :count).by(1)

        record = SyncReadRecord.last
        expect(record.data).to eq(page_data)
        expect(record.sync_run).to eq(sync_run)
        expect(record.sync).to eq(sync)
      end

      it "updates sync run pagination data" do
        subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data
        )

        sync_run.reload
        expect(sync_run.attributes).to include(
          "total_pages" => 3,
          "current_page" => 1,
          "total_records_read" => 1,
          "successful_records_read" => 1
        )
        expect(sync_run.last_extracted_at).to be_present
      end

      it "handles empty page data" do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:1")
          .and_return({ result: { data: [{ "id" => nil }] } })

        result = subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data
        )

        sync_run.reload
        expect(sync_run.total_records_read).to eq(1)
        expect(sync_run.successful_records_read).to eq(1)
        expect(result[:status]).to eq("success")
      end

      it "handles large page data" do
        large_data = Array.new(100) { |i| { "id" => i, "name" => "Test #{i}" } }
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:1")
          .and_return({ result: { data: large_data } })

        result = subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data
        )

        sync_run.reload
        expect(sync_run.total_records_read).to eq(100)
        expect(sync_run.successful_records_read).to eq(100)
        expect(result[:status]).to eq("success")
      end
    end

    context "when sync run not found" do
      it "raises RecordNotFound" do
        expect do
          subject.execute(
            sync_run_id: -1,
            signal_data: signal_data
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when workflow data missing" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:1")
          .and_return(nil)
      end

      it "raises NoMethodError" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: signal_data
          )
        end.to raise_error(NoMethodError)
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
          signal_data: signal_data
        )

        expect(result[:status]).to eq("success")
      end
    end

    context "with invalid workflow data format" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:1")
          .and_return({ result: "invalid" })
      end

      it "raises TypeError" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: signal_data
          )
        end.to raise_error(TypeError)
      end
    end

    context "with invalid signal data" do
      it "raises error when total_pages is missing" do
        invalid_signal = { workflow_id: workflow_id }

        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: invalid_signal
          )
        end.to raise_error(KeyError, /key not found: :total_pages/)
      end

      it "raises error when workflow_id is missing" do
        invalid_signal = { total_pages: 3 }

        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            signal_data: invalid_signal
          )
        end.to raise_error(KeyError, /key not found: :workflow_id/)
      end
    end

    context "when sync run is already processed" do
      before do
        sync_run.update!(
          total_pages: 5,
          current_page: 1,
          last_extracted_at: 1.hour.ago
        )
      end

      it "updates existing pagination data" do
        subject.execute(
          sync_run_id: sync_run.id,
          signal_data: signal_data
        )

        sync_run.reload
        expect(sync_run.total_pages).to eq(3) # New value from signal_data
        expect(sync_run.current_page).to eq(1)
        expect(sync_run.last_extracted_at).to be > 1.minute.ago
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
