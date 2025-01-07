# frozen_string_literal: true

module Temporal
  module Activities
    # rubocop:disable Metrics/ClassLength
    class ConvertReadRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 3600 # Set appropriate timeout in seconds
      )

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def execute(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)

        unless @sync_run.extraction_completed
          return {
            success: false,
            error: "Extraction not completed for sync run #{sync_run_id}"
          }
        end

        if @sync_run.transformation_completed
          return {
            success: false,
            error: "Transformation already completed for sync run #{sync_run_id}"
          }
        end

        if @sync_run.sync_read_records.empty?
          return {
            success: false,
            error: "No records found to convert for sync run #{sync_run_id}"
          }
        end

        begin
          @failed_records = []
          process_read_records(@sync_run)
          result = update_sync_run_status(@sync_run)

          total_records = @sync_run.total_records_read
          if @failed_records.size == total_records
            {
              success: false,
              error: "All #{total_records} records failed to convert",
              failed_records: @failed_records
            }
          else
            {
              success: true,
              transformation_completed: result[:transformation_completed],
              warning: @failed_records.any? ? "#{@failed_records.size} out of #{total_records} records failed to convert" : nil,
              failed_records: @failed_records.any? ? @failed_records : nil
            }.compact
          end
        rescue StandardError => e
          activity.logger.error(
            "Failed to convert records for sync run #{sync_run_id}: #{e.message}",
            error: e,
            sync_run_id: @sync_run.id,
            sync_id: @sync_run.sync.id
          )
          { success: false, error: e.message }
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      def process_read_records(sync_run)
        process_sync_records(sync_run)
        process_deletions(sync_run)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def process_sync_records(sync_run)
        record_ids = sync_run.sync_read_records.pluck(:id)

        Parallel.each(record_ids, in_threads: 10) do |record_id|
          ActiveRecord::Base.connection_pool.with_connection do
            sync_read_record = SyncReadRecord.find(record_id)
            activity.heartbeat
            process_single_record(sync_run, sync_read_record)
          rescue StandardError => e
            @failed_records << { id: record_id, error: e.message }
            activity.logger.error(
              "Failed to process record #{record_id}: #{e.message}",
              error: e,
              sync_run_id: sync_run.id,
              sync_id: sync_run.sync.id
            )
          ensure
            ActiveRecord::Base.connection_pool.release_connection
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def process_single_record(sync_run, sync_read_record)
        ActiveRecord::Base.transaction do
          process_record_data(sync_run, sync_read_record)
          mark_record_as_processed(sync_read_record)
        end
      end

      def process_record_data(sync_run, sync_read_record)
        if sync_run.sync.incremental_dedup?
          process_with_dedup(sync_run, sync_read_record)
        else
          create_write_records(sync_read_record)
        end
      end

      def process_with_dedup(sync_run, sync_read_record)
        redis_key = "sync:#{sync_run.sync.id}:transformed:#{sync_read_record.id}"

        activity.heartbeat
        Etl::Extractors::ConvertReadRecord::IncrementalDedupService.new(
          sync_run,
          sync_read_record.id,
          redis_key
        ).call
      end

      def mark_record_as_processed(sync_read_record)
        sync_read_record.update!(extraction_completed_at: Time.current)
      end

      def process_deletions(sync_run)
        return unless sync_run.sync.incremental_dedup?

        Etl::Extractors::ConvertReadRecord::ProcessDeletionsService.new(
          sync_run,
          sync_run.sync_read_records.last&.id,
          sync_run.sync_read_records.last&.data
        ).call
      end

      def update_sync_run_status(sync_run)
        transformation_completed = all_records_transformed?(sync_run.sync_read_records)

        sync_run.update!(
          transformation_completed: transformation_completed,
          last_transformed_at: Time.current
        )

        { transformation_completed: transformation_completed, status: "success" }
      end

      def all_records_transformed?(sync_read_records)
        sync_read_records.all? { |record| record.transformation_completed_at.present? }
      end

      def create_write_records(sync_read_record)
        return if sync_read_record.data.nil?

        unless sync_read_record.data.is_a?(Array)
          Rails.logger.error "Invalid data format for sync_read_record #{sync_read_record.id}"
          return
        end

        Array(sync_read_record.data).each do |record_data|
          create_single_write_record(sync_read_record, record_data)
        end
      end

      def create_single_write_record(sync_read_record, record_data)
        destination_action = sync_read_record.sync.connection.destination.integration_type == "database" ? :insert : :create

        SyncWriteRecord.create!(
          sync: sync_read_record.sync,
          sync_run: sync_read_record.sync_run,
          sync_read_record: sync_read_record,
          data: record_data,
          destination_action: destination_action
        )
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
