# frozen_string_literal: true

module Temporal
  module Workflows
    module Agents
      module DataAgent
        class ChatProcessingWorkflow < ::Temporal::Workflow
          # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          def execute(params)
            initialize_workflow_state(params)

            begin
              # Process message using activity
              process_result = process_message

              return handle_error(process_result[:error]) if process_result[:status] == :error

              health_result = Activities::Agents::DataAgent::CheckConnectionHealthActivity.execute!(chat_id: @chat_id)

              completed_connections = Set.new(health_result[:recently_synced_healthy_connection_ids])

              workflow.on_signal("connection_healthy") do |signal_data|
                completed_connections.add(signal_data[:connection_id])
              end

              workflow.wait_until do
                completed_connections == Set.new(@chat.connections.pluck(:id))
              end

              process_assistant_query_workflow_id = "process_assistant_query_workflow-chat_id-#{@chat.id}"

              Temporal::Workflows::Agents::DataAgent::ProcessAssistantQueryWorkflow.execute!(
                @chat.id,
                options: { task_queue: "platform_queue", workflow_id: process_assistant_query_workflow_id }
              )

              summary_result = Activities::Agents::DataAgent::GenerateSummaryActivity.execute!(chat_id: @chat_id)

              status = summary_result[:status]
              status == :success ? save_response(summary_result[:summary], process_result) : handle_error(summary_result[:error])
              handle_success(process_result)
            rescue StandardError => e
              handle_error(e.message)
            end
          end
          # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

          private

          def initialize_workflow_state(params)
            @params = params.transform_keys(&:to_s)
            @chat_id = @params["chat_id"]
            @chat = Chat.find(@chat_id)
            @content = @params["content"]
            @workspace_id = @params["workspace_id"]
          end

          def process_message
            Activities::Agents::DataAgent::ProcessMessageActivity.execute!(
              workspace_id: @workspace_id,
              chat_id: @chat_id,
              content: @content
            )
          end

          def save_response(summary, response)
            Activities::Agents::DataAgent::ChatProcessingActivity.execute!(
              chat_id: @chat_id,
              content: summary,
              tool_calls: response[:tool_calls]
            )
          end

          def handle_success(response)
            {
              status: :success,
              chat_id: @chat_id,
              content: response[:content],
              tool_calls: response[:tool_calls]
            }
          end

          def handle_error(error_message)
            workflow.logger.error("Chat processing failed: #{error_message}")

            Activities::Agents::DataAgent::ChatProcessingActivity.execute!(
              chat_id: @chat_id,
              status: :error,
              error_message: error_message
            )

            {
              status: :error,
              chat_id: @chat_id,
              error: error_message
            }
          end
        end
      end
    end
  end
end
