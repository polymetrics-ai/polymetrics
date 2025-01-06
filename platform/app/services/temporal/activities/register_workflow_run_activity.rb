# frozen_string_literal: true

module Temporal
  module Activities
    class RegisterWorkflowRunActivity < ::Temporal::Activity
      def execute(sync_run_id:, workflow_id:, run_id:)
        sync_run = SyncRun.find(sync_run_id)
        sync_run.add_read_data_workflow(workflow_id, run_id)
      end
    end
  end
end
