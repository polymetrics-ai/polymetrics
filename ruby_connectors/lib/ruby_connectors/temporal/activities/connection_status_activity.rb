# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Activities
      class ConnectionStatusActivity < ::Temporal::Activity
        def execute(connector)
          RubyConnectors::Services::ConnectorService.connect_and_fetch_status(connector)
        end
      end
    end
  end
end
