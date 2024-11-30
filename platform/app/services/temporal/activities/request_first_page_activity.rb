# frozen_string_literal: true

module Temporal
  module Activities
    class RequestFirstPageActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(workflow_id:, sync_run_id:)
        sync_run = SyncRun.find(sync_run_id)
        run_id = sync_run.get_run_id_for_workflow(workflow_id)

        begin
          Temporal.signal_workflow(
            "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
            'fetch_page',
            workflow_id,
            run_id,
            { page_number: 1 }
          )

          { status: 'success', page_number: 1 }
        rescue Temporal::Error => e
          activity.logger.error("Failed to signal first page", {
            workflow_id: workflow_id,
            sync_run_id: sync_run_id,
            page_number: page_number,
            error: e.message
          })

          { status: 'error', page_number: 1, error: e.message }
        end
      end
    end
  end
end 