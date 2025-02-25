# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Activities::Agents::DataAgent::CreateQueryExecutionActivity do
  subject(:activity) { described_class.new(activity_context) }

  let(:activity_context) { instance_double("Temporal::Activity::Context", logger: logger) }
  let(:logger) { instance_double("Logger", error: nil) }
  let(:pipeline) { create(:pipeline) }
  let(:workflow_id) { "test_workflow_123" }
  let(:query) { "SELECT * FROM users" }
  let(:workflow_store) { instance_double(WorkflowStoreService) }
  let(:workflow_data) do
    {
      "result" => {
        "columns" => %w[id name],
        "rows" => [
          { "id" => 1, "name" => "Test User" }
        ]
      }
    }
  end

  before do
    allow(WorkflowStoreService).to receive(:new).and_return(workflow_store)
  end

  describe "#execute" do
    context "when successful" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:0-1000")
          .and_return(workflow_data)
      end

      it "creates a pipeline action" do
        expect do
          activity.execute(
            pipeline_id: pipeline.id,
            workflow_id: workflow_id,
            query: query
          )
        end.to change(pipeline.pipeline_actions, :count).by(1)
      end

      it "returns success status with action id" do
        result = activity.execute(
          pipeline_id: pipeline.id,
          workflow_id: workflow_id,
          query: query
        )

        expect(result[:status]).to eq(:success)
        expect(result[:action_id]).to be_present
      end

      it "creates action with correct attributes" do
        activity.execute(
          pipeline_id: pipeline.id,
          workflow_id: workflow_id,
          query: query
        )

        action = pipeline.pipeline_actions.last
        expect(action).to have_attributes(
          action_type: "query_execution",
          position: 1,
          action_data: include(
            "query" => query,
            "workflow_id" => workflow_id,
            "execution_status" => "completed",
            "query_data" => workflow_data["result"]
          )
        )
      end

      context "when pipeline already has actions" do
        before do
          create(:pipeline_action, pipeline: pipeline, position: 3)
        end

        it "assigns correct position for new action" do
          activity.execute(
            pipeline_id: pipeline.id,
            workflow_id: workflow_id,
            query: query
          )

          expect(pipeline.pipeline_actions.last.position).to eq(4)
        end
      end
    end

    context "when pipeline not found" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:0-1000")
          .and_return(workflow_data)
      end

      it "returns error status" do
        result = activity.execute(
          pipeline_id: -1,
          workflow_id: workflow_id,
          query: query
        )

        expect(result).to eq({
                               status: :error,
                               error: "Couldn't find Pipeline with 'id'=-1"
                             })
      end
    end

    context "when workflow data not found" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .with("#{workflow_id}:0-1000")
          .and_return(nil)
      end

      it "returns error status" do
        result = activity.execute(
          pipeline_id: pipeline.id,
          workflow_id: workflow_id,
          query: query
        )

        expect(result).to eq({
                               status: :error,
                               error: "undefined method `[]' for nil:NilClass"
                             })
      end
    end

    context "when workflow store raises error" do
      before do
        allow(workflow_store).to receive(:get_workflow_data)
          .and_raise(Redis::CannotConnectError, "Connection failed")
      end

      it "returns error status" do
        result = activity.execute(
          pipeline_id: pipeline.id,
          workflow_id: workflow_id,
          query: query
        )

        expect(result).to eq({
                               status: :error,
                               error: "Connection failed"
                             })
      end
    end
  end
end
