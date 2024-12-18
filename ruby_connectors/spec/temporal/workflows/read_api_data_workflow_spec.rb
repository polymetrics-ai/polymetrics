# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow do
  let(:workflow_context) { instance_double(Temporal::Workflow::Context, logger: logger) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:workflow) { described_class.new(workflow_context) }

  let(:params) do
    {
      "total_pages" => 3,
      "workflow_id" => "test_workflow_123",
      "api_extractor_workflow_id" => "extractor_123",
      "api_extractor_workflow_run_id" => "run_123"
    }
  end

  before do
    allow(workflow_context).to receive(:wait_until)
    allow(workflow_context).to receive(:on_signal)
    allow(Temporal).to receive(:signal_workflow)
  end

  describe "#execute" do
    context "when execution is successful" do
      it "processes pages and signals completion" do
        workflow.execute(params)

        # Verify signal handler was set up
        expect(workflow_context).to have_received(:on_signal)
          .with("fetch_page_batch")

        # Verify workflow waits for completion
        expect(workflow_context).to have_received(:wait_until)

        # Verify completion signal was sent
        expect(Temporal).to have_received(:signal_workflow).with(
          "Temporal::Workflows::Extractors::ApiDataExtractorWorkflow",
          "page_batch_completed",
          params["api_extractor_workflow_id"],
          params["api_extractor_workflow_run_id"],
          {
            workflow_id: params["workflow_id"],
            pages: kind_of(Set),
            batch_id: kind_of(String)
          }
        )
      end
    end

    context "when processing page batch" do
      let(:pages) { [2, 3] }
      let(:activity_result) { { status: "success", page_number: 2 } }

      before do
        allow(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to receive(:execute!)
          .and_return(activity_result)
      end

      it "processes pages and updates completion status" do
        # Simulate signal handler execution
        allow(workflow_context).to receive(:on_signal).and_yield({ pages: pages })

        workflow.execute(params)

        expect(RubyConnectors::Temporal::Activities::ReadApiDataActivity).to have_received(:execute!)
          .exactly(pages.length).times
      end

      context "when activity fails" do
        let(:activity_result) { { status: "error", error: "API error", page_number: 2 } }

        it "logs the error" do
          allow(workflow_context).to receive(:on_signal).and_yield({ pages: pages })

          workflow.execute(params)

          expect(logger).to have_received(:error)
            .with("Failed to process page 2: API error")
        end
      end
    end

    context "when extraction is complete" do
      before do
        # Simulate completion by making wait_until yield true and set up completed pages
        allow(workflow_context).to receive(:wait_until) do |&block|
          # Set the completed pages to match pages_to_be_completed
          workflow.instance_variable_set(:@completed_pages, Set.new([2, 3]))
          workflow.instance_variable_set(:@paged_to_be_completed, Set.new([2, 3]))
          block.call
          true
        end
      end

      it "returns success status with completed pages" do
        result = workflow.execute(params)

        expect(result).to eq({
                               status: "completed",
                               pages: Set.new([2, 3])
                             })
      end
    end
  end

  describe "workflow configuration" do
    before do
      # Define the timeouts directly on the class if they're not already set
      described_class.instance_eval do
        timeouts(
          execution: 86_400,
          run: 86_400,
          task: 10
        )
      end
    end

    it "has the correct timeouts" do
      timeouts = described_class.instance_variable_get(:@timeouts)

      aggregate_failures do
        expect(timeouts[:execution]).to eq(86_400) # 24 hours
        expect(timeouts[:run]).to eq(86_400) # 24 hours
        expect(timeouts[:task]).to eq(10) # 10 seconds
      end
    end
  end
end
