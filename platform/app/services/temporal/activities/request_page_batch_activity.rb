# frozen_string_literal: true

module Temporal
  module Activities
    class RequestPageBatchActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(workflow_id:, sync_run_id:, pages:)
        sync_run = SyncRun.find(sync_run_id)

        activity.logger.info("Requesting batch of pages: #{pages}")

        run_id = sync_run.get_run_id_for_workflow(workflow_id)
        signal_workflow(workflow_id, run_id, pages)

        { status: "success", pages: pages }
      rescue ActiveRecord::RecordNotFound => e
        handle_error(e, workflow_id, sync_run_id, pages, "SyncRun not found")
      rescue Temporal::Error => e
        handle_error(e, workflow_id, sync_run_id, pages, "Temporal workflow signaling failed")
      rescue StandardError => e
        handle_error(e, workflow_id, sync_run_id, pages, "Unexpected error")
      end

      private

      def signal_workflow(workflow_id, run_id, pages)
        Temporal.signal_workflow(
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
          "fetch_page_batch",
          workflow_id,
          run_id,
          { pages: pages }
        )
      end

      def handle_error(error, workflow_id, sync_run_id, pages, context)
        error_message = {
          workflow_id: workflow_id,
          sync_run_id: sync_run_id,
          pages: pages,
          error: error.message,
          context: context
        }

        activity.logger.error("Failed to signal page batch: #{error_message}")

        { status: "error", pages: pages, error: error.message }
      end
    end
  end
end
