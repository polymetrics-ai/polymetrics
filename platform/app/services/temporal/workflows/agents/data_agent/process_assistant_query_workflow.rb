# frozen_string_literal: true

module Temporal
  module Workflows
    module Agents
      module DataAgent
        class ProcessAssistantQueryWorkflow < ::Temporal::Workflow
          def execute(chat_id)
            @chat = Chat.find(chat_id)
            @pipeline = @chat.messages.find_by(message_type: :pipeline)&.pipeline
            @read_completed = false

            return if @pipeline.blank?

            # Generate SQL query if not exists
            query_requirements = @chat.messages.where(role: :user).last.content
            Activities::Agents::DataAgent::SqlGenerationActivity.execute!(
              chat_id: @chat.id,
              query_requirements: query_requirements
            )

            return unless valid_query_generation_pipeline?

            query_action = @pipeline.pipeline_actions.find_by(action_type: :query_generation)
            return unless query_action

            execute_read_workflow(query_action)

            workflow.on_signal("database_read_completed") do |signal_data|
              @processed_result = process_database_read_signal(signal_data, query_action)
              @read_completed = true
            end

            workflow.wait_until { @read_completed }

            @processed_result
          end

          private

          def valid_query_generation_pipeline?
            @pipeline.pipeline_actions.exists?(action_type: :query_generation)
          end

          def execute_read_workflow(query_action)
            workflow_id = "platform_read_database_data-chat_id-#{@chat.id}"
            @pipeline = @chat.messages.find_by(message_type: :pipeline)&.pipeline
            query = query_action.action_data["query"]

            connection_id = @pipeline.pipeline_actions.find_by(action_type: :sync_initialization)
                                     .action_data["connections"].first["connection_id"]

            # TODO: Move this workflow to outside data agent as it might be required for database to API syncs
            # TODO: Update the logic to handle multiple connections
            Temporal::Workflows::Agents::DataAgent::ReadDatabaseDataWorkflow.execute!(
              connection_id,
              query,
              "Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow",
              options: {
                workflow_id: workflow_id,
                task_queue: "platform_queue"
              }
            )
          end

          def process_database_read_signal(signal_data, query_action)
            if signal_data[:status] == "completed"
              execution_action = create_query_execution_action(
                workflow.metadata.id,
                query_action.action_data["query"],
                signal_data.slice(:total_records, :total_batches)
              )
              handle_successful_query(execution_action, signal_data)
            else
              handle_failed_query(query_action, signal_data)
            end
          end

          def create_query_execution_action(workflow_id, query, response_data)
            Activities::Agents::DataAgent::CreateQueryExecutionActivity.execute!(
              pipeline_id: @pipeline.id,
              workflow_id: workflow_id,
              query: query,
              response_data: response_data
            )
          end

          def handle_successful_query(execution_action, result)
            {
              action_id: execution_action[:action_id],
              status: :completed,
              output: {
                total_records: result[:total_records],
                batches_processed: result[:total_batches]
              }
            }
          end

          def handle_failed_query(execution_action, result)
            {
              action_id: execution_action[:action_id],
              status: :failed,
              output: {
                error: result
              }
            }
          end
        end
      end
    end
  end
end
