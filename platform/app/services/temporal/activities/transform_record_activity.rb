# frozen_string_literal: true

module Temporal
  module Activities
    class TransformRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
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
        @sync_run.sync_read_records.find_each(batch_size: 1000) do |sync_read_record|
          transform_single_record(sync_read_record)
        end
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