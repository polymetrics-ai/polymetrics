# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConnectorWorkflows::ApiStrategy do
  let(:strategy) { described_class.new }
  let(:sync_run) { create(:sync_run) }

  describe "#workflow_class" do
    it "returns the correct workflow class" do
      expect(strategy.workflow_class).to eq("RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow")
    end
  end

  describe "#build_params" do
    it "includes base params and api-specific params" do
      workflow_id = "test_workflow_id"
      params = strategy.build_params(sync_run: sync_run, workflow_id: workflow_id)

      expect(params).to include(
        "connector_class_name" => sync_run.sync.connection.source.connector_class_name,
        "configuration" => sync_run.sync.connection.source.configuration,
        "stream_name" => sync_run.sync.stream_name,
        "page" => sync_run.current_page || 1,
        "workflow_id" => workflow_id
      )
    end

    it "uses default page 1 when current_page is nil" do
      sync_run.current_page = nil
      params = strategy.build_params(sync_run: sync_run)
      expect(params["page"]).to eq(1)
    end

    it "uses sync_run current_page when available" do
      sync_run.current_page = 5
      params = strategy.build_params(sync_run: sync_run)
      expect(params["page"]).to eq(5)
    end
  end
end
