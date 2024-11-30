# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateConnectionStatusActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(connection_id:, status:)
        connection = ::Connection.find(connection_id)
        
        case status
        when :completed
          connection.update(status: "healthy")
        when :failed
          connection.update(status: "failed")
        end
      end
    end
  end
end 