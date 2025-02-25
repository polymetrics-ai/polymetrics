# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) { instance_double("WorkflowMetadata", id: "test-workflow-id") }
  let(:workflow_context) do
    instance_double("WorkflowContext",
                    logger: double("Logger"),
                    metadata: workflow_metadata)
  end
  let(:workflow_double) do
    instance_double(
      "Workflow",
      metadata: workflow_metadata
    )
  end

  let(:chat) { create(:chat) }
  let(:pipeline) { create(:pipeline) }
  let(:user_message) { create(:message, chat: chat, role: :user, content: "Query requirements") }
  let(:pipeline_message) { create(:message, chat: chat, message_type: :pipeline, pipeline: pipeline) }
  let(:query_generation_action) do
    create(:pipeline_action,
           pipeline: pipeline,
           action_type: :query_generation,
           action_data: { "query" => "SELECT * FROM users" })
  end
  let(:sync_initialization_action) do
    create(:pipeline_action,
           pipeline: pipeline,
           action_type: :sync_initialization,
           action_data: { "connections" => [{ "connection_id" => 1 }] })
  end

  before do
    allow(workflow).to receive(:workflow).and_return(workflow_double)
    allow(Chat).to receive(:find).with(chat.id).and_return(chat)
    allow(Temporal::Activities::Agents::DataAgent::SqlGenerationActivity).to receive(:execute!)
    allow(Temporal::Workflows::Agents::DataAgent::ReadDatabaseDataWorkflow).to receive(:execute!)
    allow(Temporal::Activities::Agents::DataAgent::CreateQueryExecutionActivity).to receive(:execute!)
      .and_return({ action_id: "test-action-id" })
  end

  describe "#execute" do
    context "when pipeline exists" do
      before do
        pipeline_message
        user_message
        query_generation_action
        sync_initialization_action
      end

      it "executes SQL generation activity" do
        allow(workflow_double).to receive(:on_signal)
        allow(workflow_double).to receive(:wait_until)

        workflow.execute(chat.id)

        expect(Temporal::Activities::Agents::DataAgent::SqlGenerationActivity).to have_received(:execute!).with(
          chat_id: chat.id,
          query_requirements: "Query requirements"
        )
      end

      it "starts read database workflow" do
        allow(workflow_double).to receive(:on_signal)
        allow(workflow_double).to receive(:wait_until)

        workflow.execute(chat.id)

        expect(Temporal::Workflows::Agents::DataAgent::ReadDatabaseDataWorkflow).to have_received(:execute!).with(
          1,
          "SELECT * FROM users",
          "Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow",
          options: {
            workflow_id: "platform_read_database_data-chat_id-#{chat.id}",
            task_queue: "platform_queue"
          }
        )
      end

      context "when database read signal is received" do
        let(:signal_data) do
          {
            status: "completed",
            total_records: 100,
            total_batches: 2
          }
        end

        let(:expected_result) do
          {
            action_id: "test-action-id",
            status: :completed,
            output: {
              total_records: 100,
              batches_processed: 2
            }
          }
        end

        it "creates query execution action and returns success response" do
          # Set up the signal handling to capture and store the result
          signal_result = nil
          allow(workflow_double).to receive(:on_signal).with("database_read_completed") do |&block|
            signal_result = block.call(signal_data)
          end

          # Mock wait_until to execute the signal handler and return its result
          allow(workflow_double).to receive(:wait_until) do |&block|
            block&.call
            signal_result
          end

          result = workflow.execute(chat.id)

          expect(Temporal::Activities::Agents::DataAgent::CreateQueryExecutionActivity).to have_received(:execute!).with(
            pipeline_id: pipeline.id,
            workflow_id: "test-workflow-id",
            query: "SELECT * FROM users",
            response_data: { total_records: 100, total_batches: 2 }
          )

          expect(result).to eq(expected_result)
        end
      end
    end

    context "when pipeline does not exist" do
      it "returns nil" do
        expect(workflow.execute(chat.id)).to be_nil
      end
    end

    context "when query generation action does not exist" do
      before do
        pipeline_message
      end

      it "returns nil" do
        expect(workflow.execute(chat.id)).to be_nil
      end
    end

    context "when database read fails" do
      let(:error_signal_data) do
        {
          status: "failed",
          error: "Database connection error"
        }
      end
      let(:expected_error_result) do
        {
          action_id: query_generation_action.id,
          status: :failed,
          output: {
            error: error_signal_data
          }
        }
      end

      before do
        pipeline_message
        query_generation_action
        sync_initialization_action
      end

      it "handles the failure appropriately" do
        # Set up the signal handling to capture and store the result
        signal_result = nil
        allow(workflow_double).to receive(:on_signal).with("database_read_completed") do |&block|
          signal_result = block.call(error_signal_data)
        end

        # Mock wait_until to execute the signal handler and return its result
        allow(workflow_double).to receive(:wait_until) do |&block|
          block&.call
          signal_result
        end

        result = workflow.execute(chat.id)
        expect(result[:status]).to eq(expected_error_result[:status])
        expect(result[:output]).to eq(expected_error_result[:output])
      end
    end
  end
end
