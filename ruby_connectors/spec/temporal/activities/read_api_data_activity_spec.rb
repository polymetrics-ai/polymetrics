# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Activities::ReadApiDataActivity do
  let(:context) { instance_double(Temporal::Activity::Context, logger: logger) }
  let(:logger) { instance_double(Logger, error: nil) }
  let(:activity) { described_class.new(context) }
  let(:workflow_store) { instance_double(RubyConnectors::Services::Redis::WorkflowStoreService) }
  let(:workflow_id) { "test_workflow_123" }
  let(:page) { 1 }

  let(:params) do
    {
      workflow_id: workflow_id,
      page: page,
      connector_class_name: "Github",
      configuration: {
        "personal_access_token" => "test_token",
        "repository" => "test/repo"
      },
      stream_name: "branches"
    }
  end

  let(:reader) { instance_double(RubyConnectors::GithubConnector::Reader) }
  let(:read_result) do
    {
      data: [{ name: "main" }],
      page: 1,
      total_pages: 1
    }
  end

  before do
    allow(RubyConnectors::Services::Redis::WorkflowStoreService).to receive(:new).and_return(workflow_store)
    allow(workflow_store).to receive(:store_workflow_data)
    allow(reader).to receive(:read).and_return(read_result)
    allow(Temporal).to receive(:logger).and_return(logger)
  end

  describe "#execute" do
    context "when execution is successful" do
      before do
        allow(RubyConnectors::GithubConnector::Reader).to receive(:new).and_return(reader)
      end

      it "reads and stores the data successfully" do
        result = activity.execute(params)

        expect(reader).to have_received(:read).with(
          params[:stream_name],
          params[:page]
        )

        expect(workflow_store).to have_received(:store_workflow_data).with(
          "#{workflow_id}:#{page}",
          read_result
        )

        expect(result).to eq({
                               status: "success",
                               workflow_id: workflow_id,
                               total_pages: read_result[:total_pages],
                               page_number: page
                             })
      end
    end

    context "when connector class is not found" do
      let(:params) { super().merge(connector_class_name: "NonExistent") }

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
                               status: "error",
                               workflow_id: workflow_id,
                               current_page: page,
                               error: "uninitialized constant RubyConnectors::NonexistentConnector"
                             })
      end
    end

    context "when reader raises an error" do
      before do
        allow(RubyConnectors::GithubConnector::Reader).to receive(:new).and_return(reader)
        allow(reader).to receive(:read).and_raise(StandardError.new("API error"))
      end

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
                               status: "error",
                               workflow_id: workflow_id,
                               current_page: page,
                               error: "API error"
                             })
      end
    end

    context "when workflow store fails" do
      before do
        allow(RubyConnectors::GithubConnector::Reader).to receive(:new).and_return(reader)
        allow(workflow_store).to receive(:store_workflow_data)
          .and_raise(Redis::CannotConnectError.new("Connection failed"))
      end

      it "returns error status with message" do
        result = activity.execute(params)

        expect(result).to eq({
                               status: "error",
                               workflow_id: workflow_id,
                               current_page: page,
                               error: "Connection failed"
                             })
      end
    end
  end

  describe "activity configuration" do
    it "has correct retry policy" do
      retry_policy = described_class.instance_variable_get(:@retry_policy)

      expect(retry_policy[:interval]).to eq(2)
      expect(retry_policy[:backoff]).to eq(2)
      expect(retry_policy[:max_attempts]).to eq(5)
    end

    it "has correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      expect(timeouts[:start_to_close]).to eq(1800) # 30 minutes
      expect(timeouts[:schedule_to_close]).to eq(2000) # ~33 minutes
      expect(timeouts[:schedule_to_start]).to eq(120) # 2 minutes
      expect(timeouts[:heartbeat]).to eq(120) # 2 minutes
    end
  end
end
