# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::CreateDefaultAnalyticsDbService do
  let(:workspace) { create(:workspace) }

  describe "#call" do
    it "creates a new DuckDB connector" do
      expect { workspace }.to change(Connector, :count).by(1)
    end

    it "creates a connector with correct attributes" do
      workspace
      connector = Connector.last

      expect(connector).to have_attributes(
        workspace: workspace, name: "Default DuckDB", connector_class_name: "duckdb",
        description: "Default local analytics database for the workspace",
        connector_language: "ruby", connected: true, default_analytics_db: true
      )
    end

    it "sets the correct configuration for the connector" do
      workspace
      connector = Connector.last

      expected_config = {
        database: "analytics_db_#{workspace.id}",
        credentials: { local: { path: "analytics.duckdb" } }
      }

      expect(connector.configuration.deep_symbolize_keys).to eq(expected_config)
    end
  end
end
