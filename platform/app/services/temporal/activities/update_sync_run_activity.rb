# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateSyncRunActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1.2,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 30, # 30 seconds
        schedule_to_close: 60 # 1 minute
      )

      def execute(sync_run_id:, attributes:)
        sync_run = SyncRun.find(sync_run_id)

        ActiveRecord::Base.transaction do
          sync_run.update!(attributes)
        end

        { success: true }
      rescue ActiveRecord::RecordNotFound => e
        activity.logger.error("SyncRun not found", { sync_run_id: sync_run_id, error: e.message })
        { success: false, error: "SyncRun not found: #{sync_run_id}" }
      rescue StandardError => e
        activity.logger.error("Failed to update sync run", {
                                sync_run_id: sync_run_id,
                                attributes: attributes,
                                error: e.message
                              })
        { success: false, error: e.message }
      end
    end
  end
end
