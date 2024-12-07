# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogs::FetchSchemaService do
  let(:connector_class_name) { "github" }
  let(:service) { described_class.new(connector_class_name) }

  describe "#call" do
    let(:workflow_id) { "mock_workflow_id" }
    let(:run_id) { "mock_run_id" }
    let(:mock_result) { { "branches" => [] } }

    before do
      allow(service).to receive(:generate_workflow_id).and_return(workflow_id)
      allow(Temporal).to receive_messages(start_workflow: run_id, await_workflow_result: mock_result)
    end

    context "when the workflow succeeds" do
      it "fetches the schema for GitHub connector" do
        result = service.call
        expect(result).to be_a(Hash)
        expect(result).to have_key("branches")
      end

      it "starts the workflow with correct parameters" do
        service.call
        expect(Temporal).to have_received(:start_workflow).with(
          "RubyConnectors::Temporal::Workflows::FetchSchemaWorkflow",
          connector_class_name,
          options: service.send(:workflow_options, workflow_id)
        )
      end

      it "awaits the workflow result with correct parameters" do
        service.call
        expect(Temporal).to have_received(:await_workflow_result).with(
          "RubyConnectors::Temporal::Workflows::FetchSchemaWorkflow",
          workflow_id: workflow_id,
          run_id: run_id
        )
      end
    end

    context "when the workflow fails" do
      before do
        allow(Temporal).to receive(:start_workflow).and_raise(GRPC::Unavailable.new("14:Connection refused"))
      end

      it "raises an error" do
        expect { service.call }.to raise_error(GRPC::Unavailable, /14:Connection refused/)
      end
    end
  end
end
