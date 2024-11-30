# frozen_string_literal: true

module Temporal
  module Activities
    class LogConnectionErrorActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(connection_id:, error_message:)
        connection = ::Connection.find(connection_id)
        
        # connection.connection_logs.create!(
        #   log_type: :error,
        #   message: error_message,
        #   emitted_at: Time.current
        # )

        Rails.logger.error("Connection #{connection_id} failed: #{error_message}")
      end
    end
  end
end 