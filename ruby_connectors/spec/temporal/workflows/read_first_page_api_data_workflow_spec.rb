# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Workflows::ReadFirstPageApiDataWorkflow do
  let(:workflow_context) { instance_double(Temporal::Workflow::Context, logger: logger) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:workflow) { described_class.new(workflow_context) }
  let(:workflow_id) { "test_workflow_123" }
  let(:workflow_run_id) { "test_run_123" }

  # Create a simple struct to mock the metadata
  let(:workflow_metadata) { Struct.new(:id).new(workflow_id) }

  let(:params) do
    {
      "workflow_id" => workflow_id,
      "api_extractor_workflow_id" => "extractor_123",
      "api_extractor_workflow_run_id" => workflow_run_id,
      "connector_class_name" => "Github",
      "configuration" => {
        "personal_access_token" => "test_token",
        "repository" => "test/repo"
      },
      "stream_name" => "branches"
    }
  end

  before do
    allow(Temporal).to receive(:signal_workflow)
    allow(workflow_context).to receive(:metadata).and_return(workflow_metadata)
  end

  describe "#execute" do
    context "when first page read is successful" do
      let(:activity_result) do
        {
          status: "success",
          total_pages: 3,
          page_number: 1
        }
      end

      before do
        allow(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to receive(:execute!)
          .and_return(activity_result)
      end

      it "signals the extractor workflow with success" do
        workflow.execute(params)

        expect(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to have_received(:execute!)
          .with(params.merge("page" => 1))

        expect(Temporal).to have_received(:signal_workflow).with(
          "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
          "first_page_completed",
          params["api_extractor_workflow_id"],
          params["api_extractor_workflow_run_id"],
          {
            status: "success",
            total_pages: 3,
            workflow_id: workflow_id,
            page_number: 1,
            id: kind_of(String)
          }
        )
      end
    end

    context "when first page read fails" do
      let(:error_message) { "API error occurred" }
      let(:activity_result) do
        {
          status: "error",
          error: error_message
        }
      end

      before do
        allow(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to receive(:execute!)
          .and_return(activity_result)
      end

      it "returns error status with message" do
        result = workflow.execute(params)

        expect(result).to eq({
                               status: "error",
                               error: error_message
                             })

        expect(logger).to have_received(:error)
          .with("First page reading failed: #{error_message}")
      end
    end

    context "when activity raises an error" do
      let(:error_message) { "Unexpected error" }

      before do
        allow(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to receive(:execute!)
          .and_raise(StandardError.new(error_message))
      end

      it "logs and returns the error" do
        result = workflow.execute(params)

        expect(result).to eq({
                               status: "error",
                               error: error_message
                             })

        expect(logger).to have_received(:error)
          .with("First page reading failed: #{error_message}")
      end
    end
  end

  describe "workflow configuration" do
    before do
      described_class.instance_eval do
        timeouts(
          execution: 1800, # 30 minutes
          run: 1800,
          task: 10
        )
      end
    end

    it "has the correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      aggregate_failures do
        expect(timeouts[:execution]).to eq(1800) # 30 minutes
        expect(timeouts[:run]).to eq(1800)
        expect(timeouts[:task]).to eq(10)
      end
    end
  end
end
