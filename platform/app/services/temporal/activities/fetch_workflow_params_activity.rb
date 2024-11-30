# frozen_string_literal: true

module Temporal
  module Activities
    class FetchWorkflowParamsActivity < ::Temporal::Activity
      retry_policy(
        interval: 1,
        backoff: 2,
        max_attempts: 3
      )

      def execute(sync_run_id)
        sync_run = SyncRun.find(sync_run_id)

        ::Etl::Extractors::WorkflowExecutionParamsService.new(
          sync_run: sync_run
        ).call.with_indifferent_access
      end
    end
  end
end 