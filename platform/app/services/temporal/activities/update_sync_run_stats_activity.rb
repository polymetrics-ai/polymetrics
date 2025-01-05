# frozen_string_literal: true

module Temporal
  module Activities
    class UpdateSyncRunStatsActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id:, write_record_ids:)
        sync_run = SyncRun.find(sync_run_id)

        ActiveRecord::Base.transaction do
          sync_run.total_records_written += write_record_ids.size
          sync_run.successful_records_write += write_record_ids.size
          sync_run.save!
        end

        {
          status: "success",
          total_records_written: sync_run.total_records_written,
          successful_records_write: sync_run.successful_records_write
        }
      end
    end
  end
end
