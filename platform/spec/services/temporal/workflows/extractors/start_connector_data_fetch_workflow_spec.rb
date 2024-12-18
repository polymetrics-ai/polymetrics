# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Extractors::StartConnectorDataFetchWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_context) { instance_double("WorkflowContext", logger: logger) }
  let(:logger) { instance_double("Logger") }

  let(:workflow_params) do
    {
      workflow_class: "TestWorkflow",
      workflow_params: { test: "params" },
      workflow_options: {
        workflow_id: "test_workflow_123",
        task_queue: "test_queue"
      }
    }
  end

  describe "#execute" do
    context "when execution is successful" do
      let(:run_id) { "test_run_id_456" }

      before do
        allow(Temporal).to receive(:start_workflow).and_return(run_id)
      end

      it "starts the child workflow and returns success response" do
        result = workflow.execute(workflow_params)

        expect(Temporal).to have_received(:start_workflow).with(
          workflow_params[:workflow_class],
          workflow_params[:workflow_params],
          options: {
            workflow_id: workflow_params[:workflow_options][:workflow_id],
            task_queue: workflow_params[:workflow_options][:task_queue],
            parent_close_policy: :abandon
          }
        )

        expect(result).to eq({
                               success: true,
                               workflow_id: workflow_params[:workflow_options][:workflow_id],
                               run_id: run_id
                             })
      end
    end

    context "when workflow is already running" do
      let(:expected_message) { "Workflow already running #{workflow_params[:workflow_options][:workflow_id]}" }

      before do
        allow(Temporal).to receive(:start_workflow)
          .and_raise(Temporal::WorkflowExecutionAlreadyStartedFailure.new("Workflow already exists"))
        allow(logger).to receive(:info).with(expected_message)
      end

      it "logs the correct message and handles the error" do
        result = workflow.execute(workflow_params)

        expect(logger).to have_received(:info).with(expected_message)
        expect(result).to eq({
                               success: true,
                               message: "Workflow already running"
                             })
      end
    end

    context "when an unexpected error occurs" do
      let(:error_message) { "Something went wrong" }
      let(:expected_message) do
        "Failed to start child workflow #{workflow_params[:workflow_options][:workflow_id]} and error: #{error_message}"
      end

      before do
        allow(Temporal).to receive(:start_workflow)
          .and_raise(StandardError.new(error_message))
        allow(logger).to receive(:error).with(expected_message)
      end

      it "logs the correct error and returns failure response" do
        result = workflow.execute(workflow_params)

        expect(logger).to have_received(:error).with(expected_message)
        expect(result).to eq({
                               success: false,
                               error: error_message
                             })
      end
    end
  end
end
