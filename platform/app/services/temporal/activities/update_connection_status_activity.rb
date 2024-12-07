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

      def execute(connection_id:, status:)
        validate_status!(status)
        connection = ::Connection.find(connection_id)

        case status
        when :completed
          connection.update(status: "healthy")
        when :failed
          connection.update(status: "failed")
        end
      end

      private

      def validate_status!(status)
        return if VALID_STATUSES.include?(status)

        raise ArgumentError, "Invalid status: #{status}. Must be one of: #{VALID_STATUSES.join(", ")}"
      end
    end
  end
end
