# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Activities
      class ConnectionStatusActivity < ::Temporal::Activity
        retry_policy(
          interval: 1,
          backoff: 1,
          max_attempts: 3
        )

        def execute(connector)
          RubyConnectors::Services::ConnectorService.connect_and_fetch_status(connector)
        end
      end
    end
  end
end
