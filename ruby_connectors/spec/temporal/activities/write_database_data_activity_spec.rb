# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Activities::WriteDatabaseDataActivity do
  let(:activity_context) { instance_double("Temporal::Activity::Context", heartbeat: nil, logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:activity) { described_class.new(activity_context) }
  let(:workflow_store) { instance_double(RubyConnectors::Services::Redis::WorkflowStoreService) }
  let(:client) { instance_double("RubyConnectors::DuckdbConnector::Client") }

  let(:params) do
    {
      "workflow_id" => "test_workflow_123",
      "total_batches" => 2,
      "connector_class_name" => "duckdb",
      "configuration" => { "database" => "test_db" },
      "stream_name" => "users",
      "schema" => {
        "table_schema" => { "id" => "integer", "name" => "string" },
        "schema_name" => "public",
        "database" => "test_db"
      },
      "primary_keys" => ["id"]
    }
  end

  let(:batch_data) do
    {
      "result" => {
        "records" => [
          { "id" => 1, "name" => "Test User 1" },
          { "id" => 2, "name" => "Test User 2" }
        ]
      }
    }
  end

  before do
    # Mock Temporal logger
    allow(::Temporal).to receive(:logger).and_return(logger)
    
    allow(RubyConnectors::Services::Redis::WorkflowStoreService).to receive(:new).and_return(workflow_store)
    # Return batch data for both batches
    allow(workflow_store).to receive(:get_workflow_data).with("#{params["workflow_id"]}:1").and_return(batch_data)
    allow(workflow_store).to receive(:get_workflow_data).with("#{params["workflow_id"]}:2").and_return(batch_data)
    
    allow(RubyConnectors::DuckdbConnector::Client).to receive(:new).and_return(client)
    allow(client).to receive(:write)
  end

  describe "#execute" do
    context "when successful" do
      it "processes all batches and returns success" do
        result = activity.execute(params)

        expect(result).to eq({
          status: "success",
          records_written: 4  # 2 records * 2 batches
        })
      end

      it "initializes client only once for all batches" do
        activity.execute(params)

        expect(RubyConnectors::DuckdbConnector::Client).to have_received(:new)
          .with(params["configuration"])
          .twice
      end

      it "writes data with correct parameters" do
        activity.execute(params)

        expect(client).to have_received(:write)
          .with(
            batch_data["result"]["records"],
            table_name: params["stream_name"],
            schema: params["schema"]["table_schema"],
            schema_name: params["schema"]["schema_name"],
            database_name: params["schema"]["database"],
            primary_keys: params["primary_keys"]
          ).twice
      end

      it "sends heartbeat for each batch" do
        activity.execute(params)

        expect(activity_context).to have_received(:heartbeat).twice
      end
    end

    context "when batch data is missing" do
      before do
        allow(workflow_store).to receive(:get_workflow_data).and_return(nil)
      end

      it "skips the batch and continues processing" do
        result = activity.execute(params)

        expect(result).to eq({
          status: "success",
          records_written: 0
        })
        expect(client).not_to have_received(:write)
      end
    end

    context "when error occurs" do
      before do
        allow(client).to receive(:write)
          .and_raise(StandardError.new("Write failed"))
      end

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
          status: "error",
          error: "Write failed"
        })
      end

      it "logs the error" do
        activity.execute(params)

        expect(::Temporal.logger).to have_received(:error)
          .with("WriteDataActivity failed: Write failed")
      end
    end
  end

  describe "activity configuration" do
    it "has correct retry policy" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy).to include(
        interval: 2,
        backoff: 2,
        max_attempts: 5
      )
    end

    it "has correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts).to include(
        start_to_close: 7200,
        schedule_to_close: 7500,
        schedule_to_start: 120,
        heartbeat: 600
      )
    end
  end
end 