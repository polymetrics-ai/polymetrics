# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Workflows
      class ConnectionStatusWorkflow < ::Temporal::Workflow
        def execute(connector)
          RubyConnectors::Temporal::Activities::ConnectionStatusActivity.execute!(connector)
        end
      end
    end
  end
end
