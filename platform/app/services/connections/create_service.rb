# frozen_string_literal: true

module Connections
  class CreateService
    def initialize(connector_id, streams = nil)
      @connector = Connector.find(connector_id)
      @streams = streams || []
      @stream_hash = Digest::SHA256.hexdigest(@streams.join("-"))[0..7]
    end

    def call
      raise "Default analytics database not configured" unless workspace.default_analytics_db

      Connection.create!(
        workspace: workspace,
        source: source_connector,
        destination: destination_connector,
        name: generate_connection_name,
        schedule_type: "manual",
        status: "created",
        sync_frequency: "hourly",
        namespace: "system_defined",
        configuration: connection_configuration
      ).id
    end

    private

    attr_reader :connector, :streams

    # We maintain the configuration of the connectors in the connection
    # This will help us to keep the syncs running even if it's changed
    # in the source or destination via connector config.
    def create_connection
      Connection.create!(workspace: connector.workspace,
                         source: connector,
                         destination: connector.workspace.default_analytics_db,
                         name: "#{connector.name}_#{@stream_hash} Connection",
                         configuration: connection_configuration,
                         schedule_type: :manual,
                         status: :created,
                         sync_frequency: :hourly,
                         namespace: :system_defined)
    end

    def connection_configuration
      {
        source: connector.configuration,
        destination: connector.workspace.default_analytics_db.configuration
      }
    end

    def generate_connection_name
      if streams.any?
        "#{connector.name}_#{@stream_hash} Connection"
      else
        "#{connector.name} Connection"
      end
    end

    def workspace
      connector.workspace
    end

    def source_connector
      connector
    end

    def destination_connector
      workspace.default_analytics_db
    end
  end
end
