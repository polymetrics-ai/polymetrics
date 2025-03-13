# frozen_string_literal: true

module Temporal
  module Activities
    module Agents
      module DataAgent
        class GenerateSummaryActivity < ::Temporal::Activity
          def execute(chat_id:)
            chat = find_chat(chat_id)
            user_query = fetch_user_query(chat)
            assistant_message = find_assistant_message(chat)
            action_data = extract_action_data(assistant_message)

            validate_data_presence(user_query, assistant_message, action_data)
            generate_and_return_summary(user_query, action_data)
          rescue StandardError => e
            error_response(e.message)
          end

          private

          def find_chat(chat_id)
            Chat.find(chat_id)
          end

          def fetch_user_query(chat)
            chat.messages.where(message_type: :question, role: :user).last&.content
          end

          def find_assistant_message(chat)
            chat.messages.find_by(message_type: :pipeline, role: :assistant)
          end

          def extract_action_data(assistant_message)
            assistant_message&.pipeline&.pipeline_actions
                             &.find_by(action_type: :query_execution)
                             &.action_data
          end

          def validate_data_presence(user_query, assistant_message, action_data)
            raise ArgumentError, "User query is required" if user_query.blank?
            raise ArgumentError, "Pipeline data missing" unless assistant_message&.pipeline
            raise ArgumentError, "Data results cannot be empty" if action_data.blank?
          end

          def generate_and_return_summary(user_query, action_data)
            response = Ai::SummaryGenerationService.new.generate(
              user_query: user_query,
              data_results: action_data
            )

            {
              status: :success,
              summary: response["summary"],
              timestamp: Time.current
            }
          end

          def error_response(message)
            {
              status: :error,
              error: message
            }
          end
        end
      end
    end
  end
end
