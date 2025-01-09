# frozen_string_literal: true

module Temporal
  module Workflows
    # rubocop:disable Metrics/ClassLength
    class SyncWorkflow < ::Temporal::Workflow
      def execute(sync_run_id)
        initialize_sync(sync_run_id)

        result = perform_sync
        if result[:success]
          signal_completion(result[:status])
          result
        else
          handle_sync_failure(result[:error])
          error_result = {
            success: false,
            status: "error",
            error: result[:error]
          }
          signal_completion(error_result)
          error_result
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

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def perform_sync
        update_sync_status_activity("syncing")

        extraction_result = extract_data
        unless extraction_result[:success]
          handle_error(extraction_result[:error])
          return {
            success: false,
            status: "error",
            error: extraction_result[:error]
          }
        end

        transformation_result = transform_data
        unless transformation_result[:success]
          handle_error(transformation_result[:error])
          return {
            success: false,
            status: "error",
            error: transformation_result[:error]
          }
        end

        load_result = load_data
        unless load_result[:success]
          handle_error(load_result[:error])
          return {
            success: false,
            status: "error",
            error: load_result[:error]
          }
        end

        update_sync_status_activity("synced")
        {
          success: true,
          status: "completed"
        }
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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
          result
        else
          handle_error(result[:error] || "Unknown extraction error")
        end
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

        { success: false, error: error_message }
      end

      def transform_data
        transformation_result = Activities::TransformRecordActivity.execute!(@sync_run_id)
        return { success: false, error: transformation_result[:error] } unless transformation_result[:success]

        conversion_result = Activities::ConvertReadRecordActivity.execute!(@sync_run_id)
        if conversion_result[:success]
          {
            success: true,
            warning: [transformation_result[:warning], conversion_result[:warning]].compact.presence
          }.compact
        else
          {
            success: false,
            error: conversion_result[:error],
            failed_records: conversion_result[:failed_records]
          }
        end
      end

      def load_data
        case @destination_integration_type
        when "database"
          result = load_database_data
          { success: result[:success], error: result[:error] }
        when "api"
          { success: false, error: "API data loading not yet supported" }
        else
          { success: false, error: "Unsupported destination type: #{@destination_integration_type}" }
        end
      rescue StandardError => e
        { success: false, error: e.message }
      end

      def load_database_data
        Workflows::Loaders::DatabaseDataLoaderWorkflow.execute!(
          @sync_run_id,
          options: { workflow_id: "database_loader_#{@sync_run_id}" }
        )
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
    # rubocop:enable Metrics/ClassLength
  end
end
