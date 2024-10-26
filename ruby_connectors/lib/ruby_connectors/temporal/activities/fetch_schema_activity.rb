# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Activities
      class FetchSchemaActivity < ::Temporal::Activity
        def execute(connector_name)
          client_class = Object.const_get("RubyConnectors::#{connector_name.capitalize}Connector::Client")
          client_class.new.catalog
        end
      end
    end
  end
end
