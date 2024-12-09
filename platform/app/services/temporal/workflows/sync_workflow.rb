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

        case integration_type
        when "api"
          execute_api_extraction
        else
          {
            success: false,
            error: "Unsupported integration type: #{integration_type}",
            integration_type: integration_type
          }
        end
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
        return handle_error("Extraction result is nil") unless result
        return handle_error("Invalid extraction result format") unless result.is_a?(Hash)

        if result[:success]
          handle_successful_extraction
        else
          handle_error(result[:error] || "Unknown extraction error")
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
        @sync.error!
        error_message = error.is_a?(String) ? error : error.message
        update_sync_status_activity("error")
        Activities::LogSyncErrorActivity.execute!(
          sync_run_id: @sync_run_id,
          sync_id: @sync_run&.sync_id,
          error_message: error_message
        )
      end
    end
  end
end
