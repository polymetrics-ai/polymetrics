# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Workflows::ReadDatabaseDataWorkflow do
  let(:workflow_context) { instance_double("Temporal::Workflow::Context", logger: logger) }
  let(:logger) { instance_double("Logger", info: nil, error: nil) }
  let(:workflow) { described_class.new(workflow_context) }
  
  # Reference to the activity class that this workflow uses
  let(:activity_class) { RubyConnectors::Temporal::Activities::ReadDatabaseDataActivity }

  let(:params) do
    {
      "connector_class_name" => "duckdb",
      "configuration" => { "database" => "test_db" },
      "batch_size" => 1000
    }
  end

  before do
    allow(activity_class).to receive(:execute!)
  end

  describe "#execute" do
    context "when processing batches" do
      it "calls activity with correct parameters" do
        allow(activity_class).to receive(:execute!)
          .with(hash_including("offset" => 0, "limit" => 1000))
          .and_return({ status: "success", total_records: 2500 })

        workflow.execute(params)

        # Verify activity was called with correct parameters
        expect(activity_class).to have_received(:execute!).with(
          hash_including(
            "offset" => 0,
            "limit" => 1000,
            "connector_class_name" => "duckdb",
            "configuration" => { "database" => "test_db" }
          )
        )
      end

      it "processes multiple batches based on activity response" do
        # First batch returns total record count
        allow(activity_class).to receive(:execute!)
          .with(hash_including("offset" => 0))
          .and_return({ status: "success", total_records: 2500 })

        # Subsequent batches
        allow(activity_class).to receive(:execute!)
          .with(hash_including("offset" => 1000))
          .and_return({ status: "success" })

        allow(activity_class).to receive(:execute!)
          .with(hash_including("offset" => 2000))
          .and_return({ status: "success" })

        workflow.execute(params)

        # Verify activity was called for each batch
        expect(activity_class).to have_received(:execute!).exactly(3).times
      end
    end
  end
end