# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::WorkflowExecutionParamsService do
  let(:sync) { create(:sync) }
  let(:sync_run) { create(:sync_run, sync: sync) }
  let(:service) { described_class.new(sync_run: sync_run) }

  describe "#call" do
    context "when source is API type" do
      let(:source) { create(:connector, integration_type: :api) }
      let(:connection) { create(:connection, source: source) }
      let(:sync) { create(:sync, connection: connection) }

      it "returns workflow execution parameters for API strategy" do
        result = service.call

        expect(result).to include(
          workflow_class: "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
          workflow_params: kind_of(Hash),
          workflow_options: hash_including(
            workflow_id: "read_data_sync_id_#{sync.id}_sync_run_id_#{sync_run.id}"
          )
        )
      end
    end

    context "when source is Database type" do
      let(:source) { create(:connector, integration_type: :database) }
      let(:connection) { create(:connection, source: source) }
      let(:sync) { create(:sync, connection: connection) }

      it "returns workflow execution parameters for Database strategy" do
        result = service.call

        expect(result).to include(
          workflow_class: "RubyConnectors::Temporal::Workflows::DatabaseReadDataWorkflow",
          workflow_params: kind_of(Hash),
          workflow_options: hash_including(
            workflow_id: "read_data_sync_id_#{sync.id}_sync_run_id_#{sync_run.id}"
          )
        )
      end
    end

    context "when source has an unsupported integration type" do
      let(:source) { create(:connector) }
      let(:connection) { create(:connection, source: source) }
      let(:sync) { create(:sync, connection: connection) }

      before do
        allow(source).to receive(:integration_type).and_return("unsupported")
      end

      it "logs the error and raises UnsupportedIntegrationType" do
        expect(Rails.logger).to receive(:error).with(
          "Workflow execution error: Unsupported integration type: unsupported",
          hash_including(
            workflow_id: "read_data_sync_id_#{sync.id}_sync_run_id_#{sync_run.id}",
            sync_id: sync.id,
            connector_type: "unsupported"
          )
        )

        expect { service }.to raise_error(Etl::UnsupportedIntegrationType)
      end
    end

    context "when an error occurs" do
      let(:source) { create(:connector, integration_type: :api) }
      let(:connection) { create(:connection, source: source) }
      let(:sync) { create(:sync, connection: connection) }

      before do
        allow_any_instance_of(Etl::Extractors::ConnectorWorkflows::ApiStrategy)
          .to receive(:workflow_class)
          .and_raise(StandardError.new("Test error"))
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(
          "Workflow execution error: Test error",
          hash_including(
            workflow_id: "read_data_sync_id_#{sync.id}_sync_run_id_#{sync_run.id}",
            sync_id: sync.id,
            connector_type: source.integration_type
          )
        )

        service.call
      end
    end
  end

  describe "#workflow_strategy_for" do
    context "when integration type is api" do
      it "returns an ApiStrategy instance" do
        strategy = service.send(:workflow_strategy_for, :api)
        expect(strategy).to be_an_instance_of(Etl::Extractors::ConnectorWorkflows::ApiStrategy)
      end
    end

    context "when integration type is database" do
      it "returns a DatabaseStrategy instance" do
        strategy = service.send(:workflow_strategy_for, :database)
        expect(strategy).to be_an_instance_of(Etl::Extractors::ConnectorWorkflows::DatabaseStrategy)
      end
    end

    context "when integration type is unsupported" do
      it "raises UnsupportedIntegrationType error" do
        expect do
          service.send(:workflow_strategy_for, :unsupported)
        end.to raise_error(Etl::UnsupportedIntegrationType, "Unsupported integration type: unsupported")
      end
    end
  end

  describe "#generate_workflow_id" do
    it "generates the correct workflow ID format" do
      workflow_id = service.send(:generate_workflow_id)
      expected_id = "read_data_sync_id_#{sync.id}_sync_run_id_#{sync_run.id}"

      expect(workflow_id).to eq(expected_id)
    end
  end

  describe "#workflow_namespace" do
    context "when TEMPORAL_NAMESPACE is set" do
      before do
        allow(ENV).to receive(:[]).with("TEMPORAL_NAMESPACE").and_return("custom-namespace")
      end

      it "returns the custom namespace" do
        expect(service.send(:workflow_namespace)).to eq("custom-namespace")
      end
    end

    context "when TEMPORAL_NAMESPACE is not set" do
      before do
        allow(ENV).to receive(:[]).with("TEMPORAL_NAMESPACE").and_return(nil)
      end

      it "returns the default namespace" do
        expect(service.send(:workflow_namespace)).to eq("default-namespace")
      end
    end
  end
end
