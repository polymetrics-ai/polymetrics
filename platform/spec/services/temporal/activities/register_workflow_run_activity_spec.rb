# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::RegisterWorkflowRunActivity do
  subject { described_class.new(context) }

  let(:context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", info: nil) }
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:workflow_id) { "test_workflow_123" }
  let(:run_id) { "test_run_456" }

  describe "#execute" do
    context "when successful" do
      it "registers workflow run in sync_run" do
        subject.execute(
          sync_run_id: sync_run.id,
          workflow_id: workflow_id,
          run_id: run_id
        )

        sync_run.reload
        expect(sync_run.temporal_read_data_workflow_ids).to include({ workflow_id => run_id })
      end
    end

    context "when sync_run not found" do
      it "raises RecordNotFound" do
        expect do
          subject.execute(
            sync_run_id: -1,
            workflow_id: workflow_id,
            run_id: run_id
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when workflow_id is nil" do
      it "raises ArgumentError" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            workflow_id: nil,
            run_id: run_id
          )
        end.to raise_error(ArgumentError, "workflow_id cannot be nil")
      end
    end

    context "when run_id is nil" do
      it "raises ArgumentError" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            workflow_id: workflow_id,
            run_id: nil
          )
        end.to raise_error(ArgumentError, "run_id cannot be nil")
      end
    end

    context "when workflow_id already exists" do
      before do
        sync_run.add_read_data_workflow(workflow_id, "existing_run_id")
      end

      it "raises error" do
        expect do
          subject.execute(
            sync_run_id: sync_run.id,
            workflow_id: workflow_id,
            run_id: run_id
          )
        end.to raise_error("Workflow ID #{workflow_id} already exists")
      end
    end

    context "with multiple workflow registrations" do
      let(:another_workflow_id) { "another_workflow_123" }
      let(:another_run_id) { "another_run_456" }

      it "maintains existing workflow data when adding new ones" do
        # Register first workflow
        subject.execute(
          sync_run_id: sync_run.id,
          workflow_id: workflow_id,
          run_id: run_id
        )

        # Register second workflow
        subject.execute(
          sync_run_id: sync_run.id,
          workflow_id: another_workflow_id,
          run_id: another_run_id
        )

        sync_run.reload
        expect(sync_run.temporal_read_data_workflow_ids).to contain_exactly(
          { workflow_id => run_id },
          { another_workflow_id => another_run_id }
        )
      end
    end
  end
end
