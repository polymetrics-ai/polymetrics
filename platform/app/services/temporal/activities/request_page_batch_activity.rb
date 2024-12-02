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
        @workflow_id = workflow_id
        @sync_run = SyncRun.find(sync_run_id)
        @pages = pages

        activity.logger.info("Requesting batch of pages: #{pages}")

        run_id = @sync_run.get_run_id_for_workflow(workflow_id)
        signal_workflow(run_id)

        { status: "success", pages: pages }
      rescue StandardError => e
        handle_error(e)
      end

      private

      def signal_workflow(run_id)
        Temporal.signal_workflow(
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
          "fetch_page_batch",
          @workflow_id,
          run_id,
          { pages: @pages }
        )
      end

      def handle_error(error)
        activity.logger.error(
          "Failed to signal page batch",
          {
            workflow_id: @workflow_id,
            sync_run_id: @sync_run.id,
            pages: @pages,
            error: error.message
          }
        )

        { status: "error", pages: @pages, error: error.message }
      end
    end
  end
end
