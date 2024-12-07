# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Extractors::ConnectorWorkflows::DatabaseStrategy do
  let(:strategy) { described_class.new }
  let(:config) do
    {
      "batch_size" => 500,
      "query_timeout" => 600,
      "access_token" => "sample_token"
    }
  end
  let(:source) { create(:connector, configuration: config) }
  let(:sync) { create(:sync, connection: create(:connection, source: source)) }
  let(:sync_run) { create(:sync_run, sync: sync) }

  describe "#workflow_class" do
    it "returns the correct workflow class" do
      expect(strategy.workflow_class).to eq("RubyConnectors::Temporal::Workflows::DatabaseReadDataWorkflow")
    end
  end

  describe "#build_params" do
    it "includes base params and database-specific params from configuration" do
      params = strategy.build_params(sync_run: sync_run)

      expect(params).to include(
        "connector_class_name" => source.connector_class_name,
        "configuration" => source.configuration,
        "stream_name" => sync_run.sync.stream_name,
        "batch_size" => config["batch_size"],
        "query_timeout" => config["query_timeout"]
      )
    end

    it "uses provided batch_size when specified" do
      custom_batch_size = 1000
      params = strategy.build_params(sync_run: sync_run, batch_size: custom_batch_size)
      expect(params["batch_size"]).to eq(custom_batch_size)
    end

    it "uses configuration batch_size when batch_size not provided" do
      params = strategy.build_params(sync_run: sync_run)
      expect(params["batch_size"]).to eq(config["batch_size"])
    end
  end
end
