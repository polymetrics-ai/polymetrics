# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::ConnectionDataSyncWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata", parent_id: nil, parent_run_id: nil) }
  let(:workflow_context) { instance_double("WorkflowContext", logger: double("Logger"), metadata: workflow_metadata) }
  let(:connection) { create(:connection) }
  let(:sync) { create(:sync, connection: connection) }
  let(:sync_runs) do
    [
      create(:sync_run, sync: sync, status: "running"),
      create(:sync_run, sync: sync, status: "running")
    ]
  end
  let(:sync_run_ids) { sync_runs.map(&:id) }
  let(:workflow_double) do
    double(
      "Workflow",
      on_signal: nil,
      wait_until: true
    )
  end
  let(:redis) { Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1")) }

  before do
    # Clear Redis before each test
    redis.flushdb

    # Mock activities
    allow(Temporal::Activities::PrepareSyncRunsActivity).to receive(:execute!)
      .with(connection_id: connection.id)
      .and_return(sync_run_ids)

    allow(Temporal::Activities::UpdateConnectionStatusActivity).to receive(:execute!)
    allow(Temporal::Activities::LogConnectionErrorActivity).to receive(:execute!)
    allow(Temporal::Workflows::SyncWorkflow).to receive(:execute)
      .and_return("workflow_run_id")

    # Mock workflow methods
    allow(workflow).to receive(:workflow).and_return(workflow_double)
  end

  after do
    redis.flushdb
  end

  describe "#execute" do
    context "when all sync runs complete successfully" do
      before do
        allow(workflow_double).to receive(:on_signal).with("sync_workflow_completed") do |&block|
          sync_runs.each do |sync_run|
            # Store some transformed data in Redis
            redis_key = "sync:#{sync.id}:transformed:#{sync_run.id}"
            redis.set(redis_key, [{ "test_field" => "test_value" }].to_json)
            redis.expire(redis_key, 7.days.to_i)

            block.call(sync_run_id: sync_run.id)
          end
        end
      end

      it "prepares sync runs and starts child workflows" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::PrepareSyncRunsActivity).to have_received(:execute!)
          .with(connection_id: connection.id)
      end

      it "starts child workflows for each sync run" do
        workflow.execute(connection.id)

        sync_runs.each do |sync_run|
          expect(Temporal::Workflows::SyncWorkflow).to have_received(:execute)
            .with(
              sync_run.id,
              options: {
                workflow_id: "sync_run_#{sync_run.id}",
                task_queue: "platform_queue"
              }
            )
        end
      end

      it "updates connection status to completed" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::UpdateConnectionStatusActivity).to have_received(:execute!)
          .with(
            connection_id: connection.id,
            status: :completed
          )
      end

      it "verifies transformed data in Redis" do
        workflow.execute(connection.id)

        sync_runs.each do |sync_run|
          redis_key = "sync:#{sync.id}:transformed:#{sync_run.id}"
          expect(redis.exists?(redis_key)).to be true

          stored_data = JSON.parse(redis.get(redis_key))
          expect(stored_data).to eq([{ "test_field" => "test_value" }])

          ttl = redis.ttl(redis_key)
          expect(ttl).to be_between(0, 7.days.to_i)
        end
      end

      it "returns success result" do
        result = workflow.execute(connection.id)

        expect(result).to eq({
                               status: "completed",
                               success: true
                             })
      end
    end

    context "when some sync runs fail" do
      before do
        # Simulate one sync run completing and one failing
        allow(workflow_double).to receive(:on_signal).with("sync_workflow_completed").and_yield(sync_run_id: sync_runs.first.id)
      end

      it "updates connection status to partial_success with error message" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::UpdateConnectionStatusActivity).to have_received(:execute!)
          .with(
            connection_id: connection.id,
            status: :failed
          )
      end

      it "returns partial success result with failed syncs" do
        result = workflow.execute(connection.id)

        expect(result).to eq({
                               status: "partial_success",
                               success: false,
                               failed_syncs: [sync_runs.last.id],
                               error: "1 out of 2 syncs failed"
                             })
      end
    end

    context "when all sync runs fail" do
      before do
        allow(workflow_double).to receive(:on_signal).with("sync_workflow_completed")
      end

      it "updates connection status to failed" do
        workflow.execute(connection.id)

        expect(Temporal::Activities::UpdateConnectionStatusActivity).to have_received(:execute!)
          .with(
            connection_id: connection.id,
            status: :failed
          )
      end

      it "returns failure result with all failed syncs" do
        result = workflow.execute(connection.id)

        expect(result).to eq({
                               status: "failed",
                               success: false,
                               failed_syncs: sync_run_ids,
                               error: "All sync runs failed"
                             })
      end
    end
  end
end
