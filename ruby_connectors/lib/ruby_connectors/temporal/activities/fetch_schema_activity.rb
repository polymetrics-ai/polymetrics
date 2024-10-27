# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Activities
      # FetchSchemaActivity fetches the catalog/schema for a given connector
      # @example
      #   activity = FetchSchemaActivity.new
      #   schema = activity.execute("postgres")
      #
      # @raise [ArgumentError] if connector_name is empty
      # @raise [StandardError] if connector is invalid or schema fetch fails
      class FetchSchemaActivity < ::Temporal::Activity
        def execute(connector_name)
          client_class = Object.const_get("RubyConnectors::#{connector_name.capitalize}Connector::Client")
          client_class.new.catalog
        end
      end
    end
  end
end
