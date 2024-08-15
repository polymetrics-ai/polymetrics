# frozen_string_literal: true

module RubyConnectors
  module Services
    class ConnectorService
      def self.connect_and_fetch_status(connector)
        connector = connector.with_indifferent_access
        connect_to_connector(connector)
      end

      def self.connect_to_connector(connector)
        client_class = Object.const_get("RubyConnectors::#{connector[:connector_class_name].capitalize}Connector::Client")
        client = client_class.new(connector[:configuration])
        { connected: client.connect }
      rescue StandardError => e
        { connected: false, error_message: e.message }
      end
    end
  end
end
