# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::RequestPageBatchActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", info: nil) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:workflow_id) { "test_workflow_123" }
  let(:run_id) { "test_run_456" }
  let(:pages) { [2, 3, 4] }

  before do
    allow(SyncRun).to receive(:find).with(sync_run.id).and_return(sync_run)
    allow(sync_run).to receive(:get_run_id_for_workflow)
      .with(workflow_id)
      .and_return(run_id)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe "#execute" do
    context "when successful" do
      before do
        allow(Temporal).to receive(:signal_workflow)
      end

      it "returns success response" do
        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )

        expect(result).to eq({
                               status: "success",
                               pages: pages
                             })
      end

      it "logs the batch request" do
        expect(logger).to receive(:info)
          .with("Requesting batch of pages: #{pages}")

        subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )
      end

      it "signals workflow with correct parameters" do
        expect(Temporal).to receive(:signal_workflow)
          .with(
            "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
            "fetch_page_batch",
            workflow_id,
            run_id,
            { pages: pages }
          )

        subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )
      end
    end

    context "when sync_run not found" do
      before do
        allow(SyncRun).to receive(:find).with(sync_run.id)
                                        .and_raise(ActiveRecord::RecordNotFound.new("Couldn't find SyncRun"))
      end

      it "returns error response with correct context" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to signal page batch")
          expect(message).to include("SyncRun not found")
        end

        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )

        expect(result).to match({
                                  status: "error",
                                  pages: pages,
                                  error: "Couldn't find SyncRun"
                                })
      end
    end

    context "when temporal signal fails" do
      before do
        allow(Temporal).to receive(:signal_workflow)
          .and_raise(Temporal::Error.new("Signal failed"))
      end

      it "returns error response with correct context" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to signal page batch")
          expect(message).to include("Temporal workflow signaling failed")
          expect(message).to include("Signal failed")
        end

        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )

        expect(result).to eq({
                               status: "error",
                               pages: pages,
                               error: "Signal failed"
                             })
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Temporal).to receive(:signal_workflow)
          .and_raise(StandardError.new("Unexpected error occurred"))
      end

      it "returns error response with correct context" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to signal page batch")
          expect(message).to include("Unexpected error")
          expect(message).to include("Unexpected error occurred")
        end

        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id,
          pages: pages
        )

        expect(result).to eq({
                               status: "error",
                               pages: pages,
                               error: "Unexpected error occurred"
                             })
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
