# frozen_string_literal: true

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
  let(:result) { service.call }
  let(:service) { described_class.new(params, current_user) }

  before do
    allow(current_user).to receive(:workspace_ids).and_return([workspace.id])
    allow(Temporal).to receive_messages(start_workflow: "mock_run_id", await_workflow_result: { connected: true })
  end

  describe "#call" do
    context "when creating a new connector" do
      it "creates a new connector" do
        expect { result }.to change(Connector, :count).by(1)
      end

      it "sets basic attributes correctly" do
        expect(result).to have_attributes(
          name: "Test Connector",
          connector_class_name: "github",
          description: "A test connector",
          connector_language: "ruby"
        )
      end

      it "sets configuration and workspace correctly" do
        expect(result).to have_attributes(
          configuration: { "access_token" => "test_token" },
          workspace_id: workspace.id,
          connected: true
        )
      end

      it "generates a workflow ID" do
        expect(service.send(:generate_workflow_id)).to be_a(String)
      end

      it "starts a Temporal workflow" do
        result
        expect(Temporal).to have_received(:start_workflow).with(
          "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
          params.as_json,
          hash_including(options: hash_including(:task_queue, :workflow_id))
        )
      end

      it "awaits the workflow result" do
        result
        expect(Temporal).to have_received(:await_workflow_result).with(
          "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
          hash_including(:workflow_id, :run_id)
        )
      end
    end

    context "when the workflow result is not connected" do
      before do
        allow(Temporal).to receive(:await_workflow_result).and_return({ connected: false,
                                                                        error_message: "Connection failed" })
      end

      it "raises an error" do
        service = described_class.new(params, current_user)
        expect { service.call }.to raise_error(StandardError, "Connection failed")
      end
    end

    context "when updating an existing connector" do
      let(:existing_connector) { create(:connector, workspace: workspace) }
      let(:service) { described_class.new(params, current_user, existing_connector) }

      context "with changed configuration" do
        it "updates the connector name" do
          expect(result.name).to eq("Test Connector")
        end

        it "updates the configuration" do
          expect(result.configuration).to eq({ "access_token" => "test_token" })
        end

        it "executes the workflow" do
          result
          expect(Temporal).to have_received(:start_workflow)
        end
      end

      context "with unchanged configuration" do
        let(:params) do
          { name: "Updated Name", configuration: existing_connector.configuration }
        end

        it "updates the connector name" do
          expect(result.name).to eq("Updated Name")
        end

        it "does not execute the workflow" do
          result
          expect(Temporal).not_to have_received(:start_workflow)
        end
      end
    end
  end

  describe "private methods" do
    describe "#configuration_changed?" do
      let!(:existing_connector) { create(:connector, workspace: workspace, configuration: { "key" => "old_value" }) }
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
        expect(workflow_id).to be_a(String).and have_attributes(length: 64)
      end
    end

    describe "#workflow_options" do
      it "returns the correct options" do
        workflow_id = "test_workflow_id"
        expect(service.send(:workflow_options, workflow_id)).to eq({
                                                                     task_queue: "ruby_connectors_queue",
                                                                     workflow_id: workflow_id
                                                                   })
      end
    end
  end
end
