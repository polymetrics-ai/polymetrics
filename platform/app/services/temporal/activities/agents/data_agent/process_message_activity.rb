# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class ProcessMessageActivity < ::Temporal::Activity
          timeouts(
            start_to_close: 36000
          )

          def execute(workspace_id:, chat_id:, content:)
            assistant = initialize_assistant(workspace_id, chat_id, content)
            process_and_respond(assistant)
          rescue StandardError => e
            handle_error(e)
          end

          private

          def initialize_assistant(workspace_id, chat_id, content)
            Ai::Assistants::EtlAssistant.new(
              workspace_id: workspace_id,
              chat_id: chat_id,
              query: content
            )
          end

          def process_and_respond(assistant)
            response = assistant.process_message
            build_success_response(response)
          end

          def build_success_response(response)
            {
              status: :success,
              content: response[:content],
              tool_calls: response[:tool_calls]
            }
          end

          def handle_error(exception)
            activity.logger.error("Message processing failed: #{exception.message}")
            {
              status: :error,
              error: exception.message
            }
          end
        end
      end
    end
  end
end
