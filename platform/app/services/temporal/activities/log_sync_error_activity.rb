# frozen_string_literal: true

module Temporal
  module Activities
    class LogSyncErrorActivity < ::Temporal::Activity
      def execute(sync_run_id:, sync_id:, error_message:)
        if sync_run_id
          sync_run = SyncRun.find(sync_run_id)
          sync_run.sync_logs.create!(
            log_type: :error,
            message: error_message,
            emitted_at: Time.current
          )
        end

        Rails.logger.error("Sync #{sync_id} failed: #{error_message}")
      end
    end
  end
end
