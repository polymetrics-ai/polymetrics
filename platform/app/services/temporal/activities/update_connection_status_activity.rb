# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateConnectionStatusActivity < ::Temporal::Activity
      VALID_STATUSES = %i[completed failed].freeze

      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      # rubocop:disable Metrics/MethodLength
      def execute(connection_id:, status:, message: nil)
        validate_status!(status)
        connection = ::Connection.find(connection_id)

        case status
        when :completed
          connection.update!(status: "healthy")
          { success: true, status: "healthy" }
        when :failed
          connection.update!(status: "failed")
          { success: false, status: "failed", error: message }
        when :partial_success
          connection.update!(status: "healthy")
          { success: true, status: "healthy", warning: message }
        end
      rescue StandardError => e
        activity.logger.error("Failed to update connection status: #{e.message}")
        { success: false, status: "error", error: e.message }
      end
      # rubocop:enable Metrics/MethodLength

      private

      def validate_status!(status)
        valid_statuses = %i[completed failed partial_success]
        return if valid_statuses.include?(status.to_sym)

        raise ArgumentError, "Invalid connection status: #{status}"
      end
    end
  end
end
