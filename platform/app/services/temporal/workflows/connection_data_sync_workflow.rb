# frozen_string_literal: true

module Temporal
  module Workflows
    class ConnectionDataSyncWorkflow < ::Temporal::Workflow
      timeouts(
        execution: 86_400,  # 24 hours
        run: 21_600       # 6 hours
      )

      def execute(connection_id)
        @connection = ::Connection.find(connection_id)

        begin
          sync_run_ids = prepare_sync_runs
          start_child_workflows(sync_run_ids)
          monitor_child_workflows
          handle_completion
        rescue StandardError => e
          handle_failure(e)
        end
      end

      private

      def prepare_sync_runs
        Activities::PrepareSyncRunsActivity.execute!(connection_id: @connection.id)
      end

      def start_child_workflows(sync_run_ids)
        sync_run_ids.each do |sync_run_id|
          sync_run = SyncRun.find(sync_run_id)
          workflow_id = generate_child_workflow_id(sync_run_id)
          run_id = Temporal.start_workflow(
            Temporal::Workflows::SyncWorkflow,
            sync_run_id,
            options: workflow_options(workflow_id)
          )
          sync_run.update(temporal_workflow_id: workflow_id, temporal_run_id: run_id)
        end
      end

      def workflow_options(workflow_id)
        {
          workflow_id: workflow_id,
          task_queue: "platform_queue"
        }
      end

      def monitor_child_workflows
        workflow.on_signal("terminate_connection_#{@connection.id}") do |signal, input|
          # TODO: Implement termination logic
        end
        
        workflow.wait_until { @connection.status == "completed" }
      end

      def handle_completion
        Activities::UpdateConnectionStatusActivity.execute!(
          connection_id: @connection.id,
          status: :completed
        )
      end

      def handle_failure(error)
        Activities::UpdateConnectionStatusActivity.execute!(
          connection_id: @connection.id,
          status: :failed
        )
        log_error(error)
      end

      def generate_child_workflow_id(sync_run_id)
        "sync_run_#{sync_run_id}"
      end

      def log_error(error)
        Activities::LogConnectionErrorActivity.execute!(
          connection_id: @connection.id,
          error_message: error.message
        )
      end
    end
  end
end
