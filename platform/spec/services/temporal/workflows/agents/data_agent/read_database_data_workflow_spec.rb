# frozen_string_literal: true

require "rails_helper"

RSpec.describe Temporal::Workflows::Agents::DataAgent::ReadDatabaseDataWorkflow do
  subject(:workflow) { described_class.new(workflow_context) }

  let(:workflow_metadata) do
    instance_double(
      "WorkflowMetadata",
      id: "test-workflow-id",
      run_id: "test-run-id",
      parent_id: "parent-workflow-id",
      parent_run_id: "parent-run-id"
    )
  end

  let(:workflow_context) do
    instance_double("WorkflowContext", metadata: workflow_metadata)
  end

  let(:connection) { create(:connection) }
  let(:destination) { create(:connector, integration_type: "database") }
  let(:query) { "SELECT * FROM users" }
  let(:parent_workflow_classname) { "TestParentWorkflow" }

  before do
    allow(workflow).to receive(:workflow).and_return(
      instance_double("Workflow", metadata: workflow_metadata)
    )
    allow(Connection).to receive(:find).with(connection.id).and_return(connection)
    allow(connection).to receive(:destination).and_return(destination)
    allow(Temporal).to receive(:start_workflow)
  end

  describe "#execute" do
    it "starts the connector workflow with correct parameters" do
      result = workflow.execute(connection.id, query, parent_workflow_classname)

      expect(Temporal).to have_received(:start_workflow).with(
        "RubyConnectors::Temporal::Workflows::ReadDatabaseDataWorkflow",
        {
          query: query,
          parent_workflow_id: "parent-workflow-id",
          parent_run_id: "parent-run-id",
          connector_class_name: "duckdb",
          configuration: destination.configuration,
          parent_workflow_classname: parent_workflow_classname,
          limit: 1000
        },
        options: {
          workflow_id: "read_database_data_id-#{Digest::MD5.hexdigest(query)}",
          task_queue: "ruby_connectors_queue"
        }
      )

      expect(result).to eq({ status: :executed })
    end

    context "when connection is not found" do
      before do
        allow(Connection).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "returns an error status with the appropriate message" do
        result = workflow.execute(-1, query, parent_workflow_classname)
        expect(result[:status]).to eq(:error)
        expect(result[:error]).to include("Connection not found: ActiveRecord::RecordNotFound")
      end
    end

    context "when workflow start fails" do
      before do
        allow(Temporal).to receive(:start_workflow)
          .and_raise(StandardError.new("Workflow start failed"))
      end

      it "returns an error status with the appropriate message" do
        result = workflow.execute(connection.id, query, parent_workflow_classname)
        expect(result[:status]).to eq(:error)
        expect(result[:error]).to eq("Failed to execute query: Workflow start failed")
      end
    end
  end
end
