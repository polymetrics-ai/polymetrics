# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class CreateQueryExecutionActivity < ::Temporal::Activity
          # rubocop:disable Metrics/MethodLength
          def execute(pipeline_id:, workflow_id:, query:)
            pipeline = Pipeline.find(pipeline_id)
            store_service = ::WorkflowStoreService.new

            # Get stored data using workflow_id with offset 0 and limit 1000
            workflow_key = "#{workflow_id}:0-1000"
            workflow_data = store_service.get_workflow_data(workflow_key)

            action = pipeline.pipeline_actions.create!(
              action_type: :query_execution,
              position: next_position(pipeline),
              action_data: {
                query: query,
                workflow_id: workflow_id,
                execution_status: :completed,
                query_data: workflow_data["result"]
              }
            )

            { status: :success, action_id: action.id }
          rescue StandardError => e
            { status: :error, error: e.message }
          end
          # rubocop:enable Metrics/MethodLength

          private

          def next_position(pipeline)
            pipeline.pipeline_actions.maximum(:position).to_i + 1
          end
        end
      end
    end
  end
end
