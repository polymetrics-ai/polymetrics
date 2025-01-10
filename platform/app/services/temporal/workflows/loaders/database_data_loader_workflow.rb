# frozen_string_literal: true

module Temporal
  module Workflows
    module Loaders
      class DatabaseDataLoaderWorkflow < ::Temporal::Workflow
        timeouts(
          execution: 86_400, # 24 hours
          run: 86_400,       # 24 hours
          task: 10           # 10 seconds
        )

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def execute(sync_run_id)
          @write_completed = false
          # Start the loading process
          result = Activities::LoadDataActivity.execute!(
            sync_run_id,
            workflow.metadata.id,
            workflow.metadata.run_id
          )

          raise "Failed to start loading: #{result[:error]}" unless result[:success]

          # Set up signal handler for write completions
          workflow.on_signal("database_write_completed") do |signal_data|
            if signal_data[:status] == "success"
              @write_completed = true
              # Update write records status and sync run stats in a single activity
              Activities::UpdateWriteCompletionActivity.execute!(
                sync_run_id: sync_run_id,
                workflow_id: signal_data[:workflow_id],
                total_batches: signal_data[:total_batches]
              )
            end
          end

          # Wait for write completion
          workflow.wait_until do
            @write_completed
          end

          # Finalize the loading process
          Activities::UpdateSyncStatusActivity.execute!(
            sync_run_id: sync_run_id,
            status: :synced
          )

          { success: true, message: "Database loading completed" }
        rescue StandardError => e
          { success: false, error: e.message }
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      end
    end
  end
end
