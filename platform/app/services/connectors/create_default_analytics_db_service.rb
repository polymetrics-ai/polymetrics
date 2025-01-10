# frozen_string_literal: true

module Connectors
  class CreateDefaultAnalyticsDbService
    def initialize(workspace)
      @workspace = workspace
    end

    def call
      create_duckdb_connector
    end

    private

    def create_duckdb_connector
      Connector.create!(
        workspace: @workspace,
        name: "Default DuckDB",
        connector_class_name: "duckdb",
        description: "Default local analytics database for the workspace",
        connector_language: :ruby,
        configuration: default_duckdb_config,
        connected: true,
        default_analytics_db: true
      )
    end

    def default_duckdb_config
      {
        database: "analytics_#{Digest::SHA256.hexdigest(@workspace.id.to_s).first(8)}.duckdb",
        credentials: {
          local: {
            path: "analytics_#{Digest::SHA256.hexdigest(@workspace.id.to_s).first(8)}.duckdb"
          }
        }
      }
    end
  end
end
