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
        @sync = find_sync(sync_run_id)
        update_sync_status(status, error_message)
        build_response
      rescue StandardError => e
        handle_error(e)
      end

      private

      def find_sync(sync_run_id)
        SyncRun.find(sync_run_id).sync
      rescue ActiveRecord::RecordNotFound => e
        activity.logger.error("Sync not found", { sync_id: sync_id, error: e.message })
        raise
      end

      def update_sync_status(status, error_message)
        status_method = status_mapping[status.to_sym]
        raise ArgumentError, "Invalid sync status: #{status}" unless status_method

        @sync.public_send(status_method)
        log_status_change(status_message(status, error_message))
      end

      def status_mapping
        {
          syncing: :syncing!,
          synced: :synced!,
          error: :error!,
          cancelled: :cancelled!
        }
      end

      def status_message(status, error_message)
        case status.to_sym
        when :syncing then "Started syncing"
        when :synced then "Successfully completed sync"
        when :error then "Failed with error: #{error_message}"
        when :cancelled then "Sync cancelled"
        end
      end

      def build_response
        {
          status: @sync.status,
          updated_at: @sync.updated_at,
          sync_id: @sync.id
        }
      end

      def handle_error(error)
        activity.logger.error(
          "Failed to update sync status",
          {
            sync_id: sync_id,
            status: status,
            error: error.message
          }
        )
        raise
      end

      def log_status_change(message)
        activity.logger.info(
          "Sync status updated",
          {
            sync_id: @sync.id,
            old_status: @sync.status_was,
            new_status: @sync.status,
            message: message
          }
        )

        create_sync_log(message)
      end

      def create_sync_log(message)
        @sync.sync_logs.create!(
          log_type: :info,
          message: message,
          emitted_at: Time.current
        )
      rescue StandardError => e
        activity.logger.warn(
          "Failed to create sync log",
          { sync_id: @sync.id, error: e.message }
        )
      end
    end
  end
end
