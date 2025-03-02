# frozen_string_literal: true

module Temporal
  module Activities
    class ConvertReadRecordActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 1,
        max_attempts: 3
      )

      timeouts(
        start_to_close: 3600 # Set appropriate timeout in seconds
      )

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def execute(sync_run_id)
        @sync_run = SyncRun.find(sync_run_id)

        # Validate preconditions
        validation_result = validate_sync_run
        return validation_result if validation_result

        begin
          activity.heartbeat

          # Process the records based on sync type
          result = if @sync_run.sync.incremental_dedup?
                     # Pass the activity object to allow for heartbeats during processing
                     Etl::Extractors::ConvertReadRecord::IncrementalDedupService.new(
                       @sync_run, activity
                     ).call
                   else
                     # For non-incremental syncs, throw an error as this should be handled elsewhere
                     process_non_incremental_sync
                   end

          activity.logger.info("Convert read record activity completed for sync run #{@sync_run.id}")
          result
        rescue StandardError => e
          activity.logger.error(
            "Failed to convert records for sync run #{@sync_run.id}: #{e.message}"
          )
          { success: false, error: e.message }
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      private

      # rubocop:disable Metrics/MethodLength
      def validate_sync_run
        unless @sync_run.extraction_completed
          return {
            success: false,
            error: "Extraction not completed for sync run #{@sync_run.id}"
          }
        end

        if @sync_run.transformation_completed
          return {
            success: false,
            error: "Transformation already completed for sync run #{@sync_run.id}"
          }
        end

        return unless @sync_run.sync_read_records.empty?

        {
          success: false,
          error: "No records found to convert for sync run #{@sync_run.id}"
        }
      end
      # rubocop:enable Metrics/MethodLength

      def process_non_incremental_sync
        raise NotImplementedError,
              "Non-incremental dedup sync processing is not supported in this activity. Use a different workflow for non-incremental syncs."
      end
    end
  end
end
