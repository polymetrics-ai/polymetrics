# frozen_string_literal: true

module Temporal
  module Workflows
    class SyncWorkflow < ::Temporal::Workflow

      def execute(sync_run_id)
        @sync_run_id = sync_run_id
        @sync_run = SyncRun.find(sync_run_id)
        @sync = @sync_run.sync
        @signals_received = {}

        begin
          update_sync_status_activity('syncing')

          # Extract data from source
          extract_data
          # transform_data(sync_run)
          # load_data(sync_run)

          @sync.synced!
        rescue StandardError => e
          @sync.error!
          handle_error(e)
        end
      end

      private
      
      def extract_data
        integration_type = @sync.connection.source.integration_type
        
        extraction_result = case integration_type
                           when "api"
                             Workflows::Extractors::ApiDataExtractorWorkflow.execute!(
                               @sync_run_id,
                               options: {
                                 workflow_id: "api_data_extractor-sync_id_#{@sync.id}"
                               }
                             )
                           end

        if extraction_result[:success]
          Activities::ConvertReadRecordActivity.execute!(@sync_run_id)
          update_sync_status_activity('synced')
        else
          handle_error(extraction_result[:error])
        end
      end


      # def extract_cursor_value(record)
      #   return nil unless @cursor_field && record

      #   record[@cursor_field.to_sym]
      # end

      # def transform_data(sync_run)
      #   Activities::TransformDataActivity.execute!(sync_run_id: sync_run.id)
      # end

      # def load_data(sync_run)
      #   Activities::LoadDataActivity.execute!(sync_run_id: sync_run.id)
      # end

      def update_sync_status_activity(status)
        Activities::UpdateSyncStatusActivity.execute!(
          sync_run_id: @sync_run_id,
          status: status
        )
      end

      def handle_error(error)
        update_sync_status_activity('error')
        Activities::LogSyncErrorActivity.execute!(
          sync_run_id: @sync_run_id,
          sync_id: @sync_run&.sync_id,
          error_message: error.message
        )
      end
    end
  end
end
