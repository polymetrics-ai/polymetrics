# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::UpsertService do
  let(:current_user) { create(:user) }
  let(:workspace) { create(:workspace) }
  let(:params) do
    {
      name: "Test Connector",
      connector_class_name: "github",
      description: "A test connector",
      connector_language: "ruby",
      configuration: { "access_token" => "test_token" },
      workspace_id: workspace.id
    }
  end

  before do
    allow(current_user).to receive(:workspace_ids).and_return([workspace.id])
  end

  describe "#call" do
    context "when creating a new connector" do
      let(:service) { described_class.new(params, current_user) }

      before do
        allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: true })
      end

      it "creates a new connector" do
        expect { service.call }.to change(Connector, :count).by(1)
      end

      it "sets the correct attributes" do
        result = service.call
        expect(result).to be_a(Connector)
        expect(result.name).to eq("Test Connector")
        expect(result.connector_class_name).to eq("github")
        expect(result.description).to eq("A test connector")
        expect(result.connector_language).to eq("ruby")
        expect(result.configuration).to eq({ "access_token" => "test_token" })
        expect(result.workspace_id).to eq(workspace.id)
        expect(result.connected).to be true
      end

      it "generates a workflow ID" do
        expect(service.send(:generate_workflow_id)).to be_a(String)
      end

      it "starts a Temporal workflow" do
        expect(Temporal).to receive(:start_workflow).with(
          "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
          params.as_json,
          options: {
            task_queue: "ruby_connectors_queue",
            workflow_id: an_instance_of(String),
            workflow_execution_timeout: 30
          }
        )
        service.call
      end

      it "awaits the workflow result" do
        expect(Temporal).to receive(:await_workflow_result).with(
          "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
          workflow_id: an_instance_of(String),
          run_id: "mock_run_id",
          timeout: 25
        )
        service.call
      end

      context "when the workflow result is not connected" do
        before do
          allow(Temporal).to receive(:await_workflow_result).and_return({ connected: false,
                                                                          error_message: "Connection failed" })
        end

        it "raises an error" do
          expect { service.call }.to raise_error(StandardError, "Connection failed")
        end
      end
    end

    context "when updating an existing connector" do
      let!(:existing_connector) { create(:connector, workspace:) }
      let(:service) { described_class.new(params, current_user, existing_connector) }

      context "when configuration has changed" do
        before do
          allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: true })
        end

        it "updates the connector" do
          result = service.call
          expect(result).to eq(existing_connector)
          expect(result.name).to eq("Test Connector")
          expect(result.configuration).to eq({ "access_token" => "test_token" })
        end

        it "executes the workflow" do
          expect(Temporal).to receive(:start_workflow)
          expect(Temporal).to receive(:await_workflow_result)
          service.call
        end
      end

      context "when configuration has not changed" do
        let(:params) do
          {
            name: "Updated Name",
            configuration: existing_connector.configuration
          }
        end

        it "updates the connector without executing the workflow" do
          expect(Temporal).not_to receive(:start_workflow)
          result = service.call
          expect(result).to eq(existing_connector)
          expect(result.name).to eq("Updated Name")
        end
      end
    end
  end

  describe "private methods" do
    let(:service) { described_class.new(params, current_user) }

    describe "#configuration_changed?" do
      let!(:existing_connector) { create(:connector, workspace:, configuration: { "key" => "old_value" }) }
      let(:service) { described_class.new(params, current_user, existing_connector) }

      it "returns true when configuration has changed" do
        expect(service.send(:configuration_changed?)).to be true
      end

      it "returns false when configuration has not changed" do
        params[:configuration] = existing_connector.configuration
        expect(service.send(:configuration_changed?)).to be false
      end
    end

    describe "#generate_workflow_id" do
      it "generates a unique workflow ID" do
        workflow_id = service.send(:generate_workflow_id)
        expect(workflow_id).to be_a(String)
        expect(workflow_id.length).to eq(64) # SHA256 hash length
      end
    end

    describe "#workflow_options" do
      it "returns the correct options" do
        workflow_id = "test_workflow_id"
        options = service.send(:workflow_options, workflow_id)
        expect(options).to eq({
                                task_queue: "ruby_connectors_queue",
                                workflow_id:,
                                workflow_execution_timeout: 30
                              })
      end
    end
  end
end
