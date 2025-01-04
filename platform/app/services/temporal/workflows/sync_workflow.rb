# frozen_string_literal: true

module Temporal
  module Workflows
    class SyncWorkflow < ::Temporal::Workflow
      def execute(sync_run_id)
        initialize_sync(sync_run_id)
        
        begin
          perform_sync
          signal_completion(true)
        rescue StandardError => e
          handle_sync_failure(e)
          signal_completion(false)
        end
      end

      private

      def initialize_sync(sync_run_id)
        @sync_run_id = sync_run_id
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @signals_received = {}
        
        # Initialize integration types
        @source_integration_type = @sync.connection.source.integration_type
        @destination_integration_type = @sync.connection.destination.integration_type
      end

      def perform_sync
        update_sync_status_activity("syncing")
        extract_data
        transform_data
        load_data
        update_sync_status_activity("synced")
      end

      def extract_data
        extraction_result = perform_extraction
        process_extraction_result(extraction_result)
      end

      def perform_extraction
        case @source_integration_type
        when "api"
          execute_api_extraction
        else
          {
            success: false,
            error: "Unsupported source integration type: #{@source_integration_type}",
            integration_type: @source_integration_type
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
        # TODO: Implement extracted at timestamp for sync run
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

      def transform_data
        Activities::TransformRecordActivity.execute!(@sync_run_id)
        Activities::ConvertReadRecordActivity.execute!(@sync_run_id)
      end

      def load_data
        case @destination_integration_type
        when "database"
          load_database_data
        when "api"
          load_api_data
        else
          raise "Unsupported destination type: #{@destination_integration_type}"
        end
      end

      def load_database_data
        Workflows::Loaders::DatabaseDataLoaderWorkflow.execute!(
          @sync_run.id,
          options: { workflow_id: "database_loader_#{@sync_run.id}" }
        )
      end

      def load_api_data
        # Will be implemented later for API destinations
        raise NotImplementedError, "API data loading not yet supported"
      end

      def process_load_result(result)
        return handle_error("Load result is nil") unless result
        return handle_error("Invalid load result format") unless result.is_a?(Hash)

        if result[:success]
          handle_successful_load
        else
          handle_error(result[:error] || "Unknown load error")
        end
      end

      def handle_successful_load
        # TODO: Implement loaded_at timestamp for sync run
      end

      def signal_completion(success)
        parent_workflow_id = workflow.metadata.parent_id
        parent_run_id = workflow.metadata.parent_run_id
        
        return unless parent_workflow_id && parent_run_id

        Temporal.signal_workflow(
          "Temporal::Workflows::ConnectionDataSyncWorkflow",
          "sync_workflow_completed",
          parent_workflow_id,
          parent_run_id,
          {
            sync_run_id: @sync_run_id,
            success: success
          }
        )
      end
    end
  end
end
