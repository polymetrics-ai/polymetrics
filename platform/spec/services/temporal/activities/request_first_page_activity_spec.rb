# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::RequestFirstPageActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", info: nil) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:workflow_id) { "test_workflow_123" }
  let(:run_id) { "test_run_456" }

  before do
    allow(SyncRun).to receive(:find).with(sync_run.id).and_return(sync_run)
    allow(sync_run).to receive(:get_run_id_for_workflow)
      .with(workflow_id)
      .and_return(run_id)
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
          sync_run_id: sync_run.id
        )

        expect(result).to eq({
                               status: "success",
                               page_number: 1
                             })
      end

      it "signals workflow with correct parameters" do
        expect(Temporal).to receive(:signal_workflow)
          .with(
            "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
            "fetch_page",
            workflow_id,
            run_id,
            { page_number: 1 }
          )

        subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id
        )
      end
    end

    context "when sync_run not found" do
      before do
        allow(SyncRun).to receive(:find).with(sync_run.id)
                                        .and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises RecordNotFound" do
        expect do
          subject.execute(
            workflow_id: workflow_id,
            sync_run_id: sync_run.id
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when signal fails" do
      before do
        allow(Temporal).to receive(:signal_workflow)
          .and_raise(Temporal::Error.new("Signal failed"))
      end

      it "returns error response" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to signal first page")
          expect(message).to include("workflow_id")
          expect(message).to include("Signal failed")
        end

        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id
        )

        expect(result).to eq({
                               status: "error",
                               page_number: 1,
                               error: "Signal failed"
                             })
      end
    end

    context "when run_id is nil" do
      before do
        allow(sync_run).to receive(:get_run_id_for_workflow)
          .with(workflow_id)
          .and_return(nil)
        allow(Temporal).to receive(:signal_workflow)
          .and_raise(Temporal::Error.new("Run ID cannot be nil"))
      end

      it "returns error response" do
        expect(logger).to receive(:error) do |message|
          expect(message).to include("Failed to signal first page")
          expect(message).to include("workflow_id")
          expect(message).to include("Run ID cannot be nil")
        end

        result = subject.execute(
          workflow_id: workflow_id,
          sync_run_id: sync_run.id
        )

        expect(result[:status]).to eq("error")
        expect(result[:error]).to be_present
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
