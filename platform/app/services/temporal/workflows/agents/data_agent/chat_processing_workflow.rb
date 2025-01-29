# frozen_string_literal: true

module Temporal
  module Workflows
    module Agents
      module DataAgent
        class ChatProcessingWorkflow < ::Temporal::Workflow
          def execute(params)
            initialize_workflow_state(params)

            begin
              # Process message using activity
              process_result = process_message

              return handle_error(process_result[:error]) if process_result[:status] == :error

              # Save response using activity. TODO: Uncomment this once the process_message activity is implemented
              # save_response(process_result)

              handle_success(process_result)
            rescue StandardError => e
              handle_error(e.message)
            end
          end

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

          def save_response(response)
            Activities::Agents::DataAgent::ChatProcessingActivity.execute!(
              chat_id: @chat_id,
              content: response[:content],
              tool_calls: response[:tool_calls],
              start_to_close_timeout: 30
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
