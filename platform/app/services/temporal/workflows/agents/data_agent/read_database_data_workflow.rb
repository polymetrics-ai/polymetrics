# frozen_string_literal: true

module Temporal
  module Workflows
    module Agents
      module DataAgent
        class ReadDatabaseDataWorkflow < ::Temporal::Workflow
          # rubocop:disable Metrics/MethodLength
          def execute(connection_id, query, parent_workflow_classname)
            connection = ::Connection.find(connection_id)

            # Start the connector workflow with original parameters
            Temporal.start_workflow(
              "RubyConnectors::Temporal::Workflows::ReadDatabaseDataWorkflow",
              {
                query: query,
                parent_workflow_id: workflow.metadata.parent_id,
                parent_run_id: workflow.metadata.parent_run_id,
                connector_class_name: "duckdb",
                configuration: connection.destination.configuration,
                parent_workflow_classname: parent_workflow_classname,
                limit: 1000
              },
              options: {
                workflow_id: "read_database_data_id-#{Digest::MD5.hexdigest(query)}",
                task_queue: "ruby_connectors_queue"
              }
            )

            { status: :executed }
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end
  end
end
