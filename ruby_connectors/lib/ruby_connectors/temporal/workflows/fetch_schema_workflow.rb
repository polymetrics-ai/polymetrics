# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Workflows
      class FetchSchemaWorkflow < ::Temporal::Workflow
        def execute(connector_id)
          RubyConnectors::Temporal::Activities::FetchSchemaActivity.execute!(connector_id)
        end
      end
    end
  end
end