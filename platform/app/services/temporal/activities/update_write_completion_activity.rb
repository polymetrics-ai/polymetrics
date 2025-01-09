# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateWriteCompletionActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 60,
        heartbeat: 20,
        schedule_to_close: 120
      )

      def execute(sync_run_id:, write_record_ids:)
        ActiveRecord::Base.transaction do
          # Update write records status
          SyncWriteRecord.where(id: write_record_ids).update_all(
            status: :written
          )

          # Update sync run stats
          sync_run = SyncRun.find(sync_run_id)
          sync_run.increment!(:successful_records_write, write_record_ids.size)
        end
      rescue StandardError => e
        activity.logger.error("Failed to update write completion: #{e.message}")
        raise e
      end
    end
  end
end
