# frozen_string_literal: true

module Temporal
  module Activities
    class SyncLogActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id:, message:, log_type: :info)
        sync_run = SyncRun.find(sync_run_id)

        sync_run.sync_logs.create!(
          log_type: log_type,
          message: message,
          emitted_at: Time.current
        )

        Rails.logger.send(log_type, "Sync #{sync_run.sync_id} - #{message}")
      end
    end
  end
end
