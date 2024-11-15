# frozen_string_literal: true

module Temporal
  module Activities
    class StartSyncWorkflowsActivity < ::Temporal::Activity
      def execute(connection_id)
        ActiveRecord::Base.connection_pool.with_connection do
          @connection = ::Connection.find(connection_id)

          @connection.syncs.find_each do |sync|
            sync_run = create_sync_run(sync)
            start_sync_workflow(sync, sync_run)

            # Release connection after each iteration
            ActiveRecord::Base.connection_pool.release_connection
          end
        end
      end

      private

      def start_sync_workflow(sync, sync_run)
        workflow_id = generate_workflow_id(sync, sync_run)
        Rails.logger.info "Attempting to schedule workflow #{workflow_id}"

        Temporal.start_workflow(
          Temporal::Workflows::SyncWorkflow,
          sync_run.id,
          options: workflow_options(workflow_id)
        )
      end

      def generate_workflow_id(sync, sync_run)
        "sync_#{sync.id}_sync_run_#{sync_run.id}_connection_#{@connection.id}_#{SecureRandom.uuid}"
      end

      def workflow_options(workflow_id)
        {
          workflow_id: workflow_id,
          task_queue: "platform_queue"
        }
      end

      def create_sync_run(sync)
        sync.sync_runs.create!(
          status: :running,
          started_at: Time.current,
          total_records_read: 0,
          total_records_written: 0,
          successful_records_read: 0,
          failed_records_read: 0,
          successful_records_write: 0,
          records_failed_to_write: 0
        )
      end
    end
  end
end
