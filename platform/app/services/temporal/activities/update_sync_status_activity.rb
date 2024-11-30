# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateSyncStatusActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id:, status:, error_message: nil)
        @sync = SyncRun.find(sync_run_id).sync
        
        case status.to_sym
        when :syncing
          @sync.syncing!
          log_status_change("Started syncing")
        when :synced
          @sync.synced!
          log_status_change("Successfully completed sync")
        when :error
          @sync.error!
          log_status_change("Failed with error: #{error_message}")
        when :cancelled
          @sync.cancelled!
          log_status_change("Sync cancelled")
        else
          raise ArgumentError, "Invalid sync status: #{status}"
        end

        # Return the updated sync status
        {
          status: @sync.status,
          updated_at: @sync.updated_at,
          sync_id: @sync.id
        }
      rescue ActiveRecord::RecordNotFound => e
        activity.logger.error("Sync not found", { sync_id: sync_id, error: e.message })
        raise
      rescue StandardError => e
        activity.logger.error("Failed to update sync status", 
          { 
            sync_id: sync_id, 
            status: status, 
            error: e.message 
          }
        )
        raise
      end

      private

      def log_status_change(message)
        activity.logger.info("Sync status updated", {
          sync_id: @sync.id,
          old_status: @sync.status_was,
          new_status: @sync.status,
          message: message
        })

        create_sync_log(message)
      end

      def create_sync_log(message)
        @sync.sync_logs.create!(
          log_type: :info,
          message: message,
          emitted_at: Time.current
        )
      rescue StandardError => e
        # Log creation shouldn't fail the status update
        activity.logger.warn("Failed to create sync log", {
          sync_id: @sync.id,
          error: e.message
        })
      end
    end
  end
end 