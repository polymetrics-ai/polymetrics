# frozen_string_literal: true

module Temporal
  module Workflows
    class SyncWorkflow < ::Temporal::Workflow
      def execute(sync_run_id)
        sync_run = SyncRun.find(sync_run_id)
        sync = sync_run.sync

        begin
          sync.syncing!

          # Extract data from source
          extract_data(sync_run)
          # transform_data(sync_run)
          # load_data(sync_run)

          sync.synced!
        rescue StandardError => e
          sync.error!
          log_error(sync_run, e)
        end
      end

      private

      def extract_data(sync_run)
        Activities::ExtractDataActivity.execute!(sync_run.id)

        Activities::ConvertReadRecordActivity.execute!(sync_run.id)
      end

      # def transform_data(sync_run)
      #   Activities::TransformDataActivity.execute!(sync_run_id: sync_run.id)
      # end

      # def load_data(sync_run)
      #   Activities::LoadDataActivity.execute!(sync_run_id: sync_run.id)
      # end

      def log_error(sync_run, error)
        Activities::LogSyncErrorActivity.execute!(
          sync_run_id: sync_run&.id,
          sync_id: sync_run&.sync_id,
          error_message: error.message
        )
      end
    end
  end
end
