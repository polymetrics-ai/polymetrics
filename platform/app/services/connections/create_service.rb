# frozen_string_literal: true

module Connections
  class CreateService
    def initialize(connector_id)
      @connector = Connector.find(connector_id)
    end

    def call
      create_connection.id
    end

    private

    attr_reader :connector

    # We maintain the configuration of the connectors in the connection
    # This will help us to keep the syncs running even if it's changed
    # in the source or destination via connector config.
    def create_connection
      Connection.create!(
        workspace: connector.workspace,
        source: connector,
        destination: connector.workspace.default_analytics_db,
        name: "#{connector.name} Connection",
        configuration: {
          source: connector.configuration,
          destination: connector.workspace.default_analytics_db.configuration
        },
        schedule_type: :manual,
        status: :created,
        sync_frequency: :hourly,
        namespace: :system_defined
      )
    end
  end
end