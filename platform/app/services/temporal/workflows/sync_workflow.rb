# frozen_string_literal: true

module Temporal
  module Workflows
    class SyncWorkflow < ::Temporal::Workflow
      def execute(sync_run_id)
        initialize_sync(sync_run_id)
        perform_sync
      rescue StandardError => e
        handle_sync_failure(e)
      end

      private

      def initialize_sync(sync_run_id)
        @sync_run_id = sync_run_id
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @signals_received = {}
      end

      def perform_sync
        update_sync_status_activity("syncing")
        extract_data
        # transform_data(sync_run)
        # load_data(sync_run)
        @sync.synced!
      end

      def extract_data
        extraction_result = perform_extraction
        process_extraction_result(extraction_result)
      end

      def perform_extraction
        integration_type = @sync.connection.source.integration_type
        execute_api_extraction if integration_type == "api"
      end

      def execute_api_extraction
        Workflows::Extractors::ApiDataExtractorWorkflow.execute!(
          @sync_run_id,
          options: {
            workflow_id: "api_data_extractor-sync_id_#{@sync.id}"
          }
        )
      end

      def process_extraction_result(result)
        if result[:success]
          handle_successful_extraction
        else
          handle_error(result[:error])
        end
      end

      def handle_successful_extraction
        Activities::ConvertReadRecordActivity.execute!(@sync_run_id)
        update_sync_status_activity("synced")
      end

      def handle_sync_failure(error)
        @sync.error!
        handle_error(error)
      end

      def update_sync_status_activity(status)
        Activities::UpdateSyncStatusActivity.execute!(
          sync_run_id: @sync_run_id,
          status: status
        )
      end

      def handle_error(error)
        update_sync_status_activity("error")
        Activities::LogSyncErrorActivity.execute!(
          sync_run_id: @sync_run_id,
          sync_id: @sync_run&.sync_id,
          error_message: error.message
        )
      end
    end
  end
end
