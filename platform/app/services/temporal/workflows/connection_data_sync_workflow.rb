# frozen_string_literal: true

module Temporal
  module Workflows
    class ConnectionDataSyncWorkflow < ::Temporal::Workflow
      def execute(connection_id)
        initialize_connection(connection_id)
        sync_run_ids = prepare_sync_runs
        result = start_child_workflows(sync_run_ids)

        handle_final_status(result)
      end

      private

      def initialize_connection(connection_id)
        @connection = ::Connection.find(connection_id)
      end

      def prepare_sync_runs
        Activities::PrepareSyncRunsActivity.execute!(connection_id: @connection.id)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def start_child_workflows(sync_run_ids)
        @completed_sync_runs = Set.new

        # Set up completion signal handler
        workflow.on_signal("sync_workflow_completed") do |signal_data|
          @completed_sync_runs.add(signal_data[:sync_run_id])
        end

        sync_run_ids.each do |sync_run_id|
          sync_run = SyncRun.find(sync_run_id)
          workflow_id = generate_child_workflow_id(sync_run_id)

          run_id = Temporal::Workflows::SyncWorkflow.execute(
            sync_run_id,
            options: workflow_options(workflow_id)
          )

          sync_run.update(temporal_workflow_id: workflow_id, temporal_run_id: run_id)

          # Wait for the current sync run to complete before starting the next one
          workflow.wait_until { @completed_sync_runs.include?(sync_run_id) }
        end

        if sync_run_ids.all? { |id| @completed_sync_runs.include?(id) }
          { status: "completed", success: true }
        elsif @completed_sync_runs.any?
          { status: "partial_success", success: false, failed_syncs: sync_run_ids - @completed_sync_runs.to_a,
            error: "Some sync runs failed" }
        else
          { status: "failed", success: false, error: "All sync runs failed" }
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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

      # rubocop:disable Metrics/MethodLength
      def handle_final_status(results)
        if results[:status] == "completed"
          handle_completion
          { status: "completed", success: true }
        else
          error_message = "#{results[:failed_syncs].length} out of #{@sync_run_ids.length} syncs failed"
          Activities::UpdateConnectionStatusActivity.execute!(
            connection_id: @connection.id,
            status: :partial_success,
            message: error_message
          )

          {
            status: "partial_success",
            success: false,
            failed_syncs: results[:failed_syncs],
            error: error_message
          }
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
