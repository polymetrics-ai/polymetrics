# frozen_string_literal: true

module Temporal
  module Activities
    class PrepareSyncRunsActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(connection_id:)
        ActiveRecord::Base.connection_pool.with_connection do
          connection = ::Connection.find(connection_id)
          sync_runs_ids = []

          connection.syncs.find_each do |sync|
            sync_runs_ids << create_sync_run(sync).id
            ActiveRecord::Base.connection_pool.release_connection
          end

          sync_runs_ids
        end
      end

      private

      def create_sync_run(sync)
        sync.sync_runs.create!(
          status: :running,
          started_at: Time.current,
          total_records_read: 0,
          total_records_written: 0,
          successful_records_read: 0,
          failed_records_read: 0,
          successful_records_write: 0,
          records_failed_to_write: 0
        )
      end
    end
  end
end 