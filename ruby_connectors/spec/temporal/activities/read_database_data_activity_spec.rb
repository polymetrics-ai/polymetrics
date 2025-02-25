# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Activities::ReadDatabaseDataActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:activity) { described_class.new(activity_context) }
  let(:workflow_store) { instance_double(RubyConnectors::Services::Redis::WorkflowStoreService) }
  
  let(:params) do
    {
      "workflow_id" => "test_workflow_123",
      "parent_workflow_id" => "parent_workflow_123",
      "connector_class_name" => "duckdb",
      "configuration" => { "database" => "test_db" },
      "query" => "SELECT * FROM users",
      "offset" => 0,
      "limit" => 1000
    }
  end

  let(:reader) { instance_double(RubyConnectors::DuckdbConnector::Reader) }
  let(:read_result) do
    {
      records: [{ id: 1, name: "Test User" }],
      total_records: 100
    }
  end

  before do
    allow(RubyConnectors::Services::Redis::WorkflowStoreService).to receive(:new).and_return(workflow_store)
    allow(workflow_store).to receive(:store_workflow_data)
    allow(Temporal).to receive(:logger).and_return(logger)
  end

  describe "#execute" do
    context "when execution is successful" do
      before do
        allow(RubyConnectors::DuckdbConnector::Reader).to receive(:new).and_return(reader)
        allow(reader).to receive(:read).and_return(read_result)
      end

      it "reads and stores the data successfully" do
        result = activity.execute(params)

        expect(reader).to have_received(:read).with(
          query: params["query"],
          offset: params["offset"],
          limit: params["limit"]
        )

        workflow_key = "#{params["parent_workflow_id"]}:#{params["offset"]}-#{params["limit"]}"
        expect(workflow_store).to have_received(:store_workflow_data).with(
          workflow_key,
          read_result
        )

        expect(result).to eq({
          status: "success",
          workflow_id: params["workflow_id"],
          workflow_key: workflow_key,
          offset: 0,
          limit: 1000,
          total_records: read_result[:total_records]
        })
      end
    end

    context "when connector class is not found" do
      let(:params) { super().merge("connector_class_name" => "NonExistent") }

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
          workflow_id: params["workflow_id"],
          offset: 0,
          error: "uninitialized constant RubyConnectors::NonexistentConnector",
          status: "error"
        })

        expect(logger).to have_received(:error)
          .with(/ReadDatabaseDataActivity failed: uninitialized constant/)
      end
    end

    context "when reader raises an error" do
      let(:error_message) { "Database connection failed" }

      before do
        allow(RubyConnectors::DuckdbConnector::Reader).to receive(:new).and_return(reader)
        allow(reader).to receive(:read).and_raise(StandardError.new(error_message))
      end

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
          workflow_id: params["workflow_id"],
          offset: 0,
          error: error_message,
          status: "error"
        })

        expect(logger).to have_received(:error)
          .with("ReadDatabaseDataActivity failed: #{error_message}")
      end
    end
  end

  describe "activity configuration" do
    it "has the correct retry policy" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      aggregate_failures do
        expect(retry_policy[:interval]).to eq(2)
        expect(retry_policy[:backoff]).to eq(2)
        expect(retry_policy[:max_attempts]).to eq(5)
      end
    end

    it "has the correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      aggregate_failures do
        expect(timeouts[:start_to_close]).to eq(1800)
        expect(timeouts[:schedule_to_close]).to eq(2000)
        expect(timeouts[:schedule_to_start]).to eq(120)
        expect(timeouts[:heartbeat]).to eq(120)
      end
    end
  end
end 