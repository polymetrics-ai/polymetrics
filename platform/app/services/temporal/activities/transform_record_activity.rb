# frozen_string_literal: true

module Temporal
  module Activities
    class TransformRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 600,  # 10 minutes
        heartbeat: 120,       # 2 minutes
        schedule_to_close: 1800  # 30 minutes
      )

      def execute(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync

        return if @sync_run.extraction_completed
        return if @sync_run.sync_read_records.empty?

        transform_read_records
        update_sync_run_status
      end

      private

      def transform_read_records
        record_ids = @sync_run.sync_read_records.pluck(:id)
        processed_records = Set.new

        Parallel.each(record_ids, in_threads: 10) do |record_id|
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              sync_read_record = SyncReadRecord.find(record_id)
              transform_single_record(sync_read_record)
              processed_records.add(record_id)
              activity.heartbeat
            rescue StandardError => e
              handle_record_error(record_id, e)
            ensure
              ActiveRecord::Base.connection_pool.release_connection
            end
          end
        end
      end

      def handle_record_error(record_id, error)
        activity.logger.error(
          "Failed to transform record #{record_id}: #{error.message}",
          error: error,
          sync_run_id: @sync_run.id,
          sync_id: @sync.id
        )
      end

      def transform_single_record(sync_read_record)
        return unless sync_read_record.data.is_a?(Array)

        transformed_data = sync_read_record.data.map do |record|
          transform_record_data(record)
        end

        store_transformed_data(sync_read_record.id, transformed_data)
        mark_record_as_transformed(sync_read_record)
      end

      def transform_record_data(record)
        transformed_record = {}
        mapping = @sync.destination_database_schema["mapping"]

        # Map fields according to destination schema
        mapping.each do |field_map|
          source_field = field_map["from"]
          dest_field = field_map["to"]

          transformed_record[dest_field] = record[source_field]
        end

        transformed_record
      end

      def store_transformed_data(record_id, data)
        redis_key = "sync:#{@sync.id}:transformed:#{record_id}"
        redis.set(redis_key, data.to_json)
        redis.expire(redis_key, 7.days.to_i)
      end

      def mark_record_as_transformed(sync_read_record)
        sync_read_record.update!(
          transformation_completed_at: Time.current
        )
      end

      def update_sync_run_status
        transformation_completed = @sync_run.sync_read_records.all? do |record|
          record.transformation_completed_at.present?
        end

        @sync_run.update!(
          transformation_completed: transformation_completed,
          last_transformed_at: Time.current
        )
      end

      def redis
        @redis ||= initialize_redis
      end

      def generate_record_signature(record)
        Digest::SHA256.hexdigest(record.to_json)
      end
    end
  end
end
