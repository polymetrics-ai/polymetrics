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
        database: "analytics_db_#{@workspace.id}",
        credentials: {
          local: {
            path: "analytics.duckdb"
          }
        }
      }
    end
  end
end
