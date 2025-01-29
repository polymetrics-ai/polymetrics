# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class ChatProcessingActivity < ::Temporal::Activity
          timeouts(
            start_to_close: 36000
          )

          def execute(chat_id:, content: nil, tool_calls: nil, status: :success, error_message: nil)
            chat = Chat.find(chat_id)

            ActiveRecord::Base.transaction do
              if status == :success
                create_success_message(chat, content)
                update_tool_calls(chat, tool_calls)
              else
                create_error_message(chat, error_message)
                chat.failed!
              end
            end

            { status: status }
          rescue StandardError => e
            activity.logger.error("Failed to save chat response: #{e.message}")
            { status: :error, error: e.message }
          end

          private

          def create_success_message(chat, content)
            chat.messages.create!(
              content: content,
              role: :assistant,
              message_type: :text
            )
          end

          def create_error_message(chat, error_message)
            chat.messages.create!(
              content: "Error processing message: #{error_message}",
              role: :system,
              message_type: :text
            )
          end

          def update_tool_calls(chat, tool_calls)
            return if tool_calls.blank?

            chat.update!(tool_call_data: tool_calls)
          end
        end
      end
    end
  end
end
