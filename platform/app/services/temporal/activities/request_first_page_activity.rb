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
        @workflow_id = workflow_id
        @sync_run = SyncRun.find(sync_run_id)

        signal_first_page
      end

      private

      def signal_first_page
        run_id = @sync_run.get_run_id_for_workflow(@workflow_id)
        send_fetch_page_signal(run_id)
      rescue Temporal::Error => e
        handle_signal_error(e)
      end

      def send_fetch_page_signal(run_id)
        Temporal.signal_workflow(
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow",
          "fetch_page",
          @workflow_id,
          run_id,
          { page_number: 1 }
        )

        { status: "success", page_number: 1 }
      end

      def handle_signal_error(error)
        error_message = {
          workflow_id: @workflow_id,
          sync_run_id: @sync_run.id,
          page_number: 1,
          error: error.message
        }

        activity.logger.error("Failed to signal first page: #{error_message}")

        { status: "error", page_number: 1, error: error.message }
      end
    end
  end
end
