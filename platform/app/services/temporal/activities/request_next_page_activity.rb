# frozen_string_literal: true

module Temporal
  module Activities
    class RequestNextPageActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(workflow_id:, sync_run_id:)
        sync_run = SyncRun.find(sync_run_id)
        run_id = sync_run.get_run_id_for_workflow(workflow_id)
        next_page = sync_run.current_page + 1
        activity.logger.error("sending signal for page: #{next_page}")

        signal_workflow(workflow_id, run_id, next_page)

        { status: 'success', page_number: next_page } 
      rescue Temporal::Error => e
        activity.logger.error("Failed to signal next page: #{e.message}")
        { status: 'error', page_number: next_page, error: e.message }
      end

      private

      def signal_workflow(workflow_id, run_id, page_number)
        Temporal.signal_workflow(
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
          'fetch_page',
          workflow_id,
          run_id,
          { page_number: page_number }
        )
      end
    end
  end
end 