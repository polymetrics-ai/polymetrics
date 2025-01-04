# frozen_string_literal: true

module Temporal
  module Activities
    class FetchPendingRecordsActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 120,  # 2 minutes
        heartbeat: 30,        # 30 seconds
        schedule_to_close: 180 # 3 minutes
      )

      def execute(sync_run_id)
        sync_write_record_ids = SyncWriteRecord.where(sync_run_id: sync_run_id, status: :pending).pluck(:id)
        redis_key = "sync_run_#{sync_run_id}_pending_records"
        redis = initialize_redis
        redis.set(redis_key, sync_write_record_ids.to_json)
        
        {
          status: :success,
          redis_key: redis_key
        }
      end
    end
  end
end 