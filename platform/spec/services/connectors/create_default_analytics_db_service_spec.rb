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
      config = connector.configuration.deep_symbolize_keys

      # Test the structure and presence of required keys
      expect(config).to include(:database, :credentials)
      expect(config[:credentials]).to include(:local)
      expect(config[:credentials][:local]).to include(:path)

      # Test that both database and path use the same identifier
      db_identifier = config[:database].split("_").last.sub(".duckdb", "")
      path_identifier = config[:credentials][:local][:path].split("_").last.sub(".duckdb", "")

      expect(db_identifier).to eq(path_identifier)
      expect(config[:database]).to end_with(".duckdb")
      expect(config[:credentials][:local][:path]).to end_with(".duckdb")
    end
  end
end
