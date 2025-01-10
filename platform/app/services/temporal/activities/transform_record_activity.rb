# frozen_string_literal: true

module Temporal
  module Activities
    # rubocop:disable Metrics/ClassLength
    class TransformRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 600,  # 10 minutes
        heartbeat: 120,       # 2 minutes
        schedule_to_close: 1800 # 30 minutes
      )

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def execute(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync

        unless @sync_run.extraction_completed
          return {
            success: false,
            error: "Extraction already completed for sync run #{sync_run_id}"
          }
        end

        if @sync_run.sync_read_records.empty?
          return {
            success: false,
            error: "No records found to transform for sync run #{sync_run_id}"
          }
        end

        begin
          transform_read_records

          total_records = @sync_run.total_records_read
          if @failed_records.size == total_records
            {
              success: false,
              error: "All #{total_records} records failed to transform",
              failed_records: @failed_records
            }
          else
            {
              success: true,
              warning: @failed_records.any? ? "#{@failed_records.size} out of #{total_records} records failed to transform" : nil,
              failed_records: @failed_records.any? ? @failed_records : nil
            }.compact
          end
        rescue StandardError => e
          activity.logger.error(
            "Failed to transform records for sync run #{sync_run_id}: #{e.message}",
            error: e,
            sync_run_id: @sync_run.id,
            sync_id: @sync.id
          )
          { success: false, error: e.message }
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def transform_read_records
        record_ids = @sync_run.sync_read_records.pluck(:id)
        @failed_records = []
        processed_records = Set.new

        Parallel.each(record_ids, in_threads: 10) do |record_id|
          ActiveRecord::Base.connection_pool.with_connection do
            sync_read_record = SyncReadRecord.find(record_id)
            result = transform_single_record(sync_read_record)
            activity.heartbeat
            if result[:success]
              processed_records.add(record_id)
            else
              @failed_records << { id: record_id, error: result[:error] }
            end
          rescue StandardError => e
            @failed_records << { id: record_id, error: e.message }
            handle_record_error(record_id, e)
          ensure
            ActiveRecord::Base.connection_pool.release_connection
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def handle_record_error(record_id, error)
        activity.logger.error(
          "Failed to transform record #{record_id}: #{error.message}",
          error: error,
          sync_run_id: @sync_run.id,
          sync_id: @sync.id
        )
      end

      def transform_single_record(sync_read_record)
        return { success: false, error: "Data is not an array" } unless sync_read_record.data.is_a?(Array)

        transformed_data = sync_read_record.data.map do |record|
          transform_record_data(record)
        end

        store_transformed_data(sync_read_record.id, transformed_data)
        { success: true, transformed_data: transformed_data }
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

      def redis
        @redis ||= initialize_redis
      end

      def generate_record_signature(record)
        Digest::SHA256.hexdigest(record.to_json)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
