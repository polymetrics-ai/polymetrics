# frozen_string_literal: true

module Ai
  module Tools
    module Sync
      class SyncInitiatorTool < BaseTool
        define_function(
          :initiate_sync,
          description: "Initiates data synchronization for all connections in a chat"
        )

        def initialize(workspace_id:, chat_id:)
          @workspace_id = workspace_id
          @chat_id = chat_id
          @chat = Chat.find(@chat_id)
        end

        def initiate_sync
          sync_results = process_connections
          create_sync_pipeline_action(sync_results)
          build_success_response(sync_results)
        rescue StandardError => e
          handle_error(e.message)
        end

        private

        def process_connections
          @chat.connections.filter_map do |connection|
            next if connection.running?

            process_connection_sync(connection)
          end
        end

        def recently_synced_healthy_connection?(connection)
          connection.healthy? && recent_successful_sync?(connection)
        end

        def recent_successful_sync?(connection)
          connection.syncs.all? { |sync| sync.sync_runs.last.completed_at > 30.minutes.ago }
        end

        def process_connection_sync(connection)
          workflow_run_id = Connections::StartDataSyncService.new(connection).call unless recently_synced_healthy_connection?(connection)
          build_connection_result(connection, workflow_run_id)
        rescue StandardError => e
          build_connection_error(connection, e)
        end

        def build_connection_result(connection, workflow_run_id)
          {
            connection_id: connection.id,
            connection_workflow_run_id: workflow_run_id,
            status: :success
          }
        end

        def build_connection_error(connection, error)
          {
            connection_id: connection.id,
            error: error.message,
            status: :failed
          }
        end

        def create_sync_pipeline_action(sync_results)
          return unless (pipeline = @chat.messages.pipeline.last&.pipeline)

          next_position = pipeline.pipeline_actions.maximum(:position).to_i + 1
          action_data = { connections: formatted_connection_data(sync_results) }

          pipeline.pipeline_actions.create!(
            action_type: :sync_initialization,
            position: next_position,
            action_data: action_data
          )
        end

        def formatted_connection_data(sync_results)
          sync_results.map do |result|
            result.slice(:connection_id, :connection_workflow_run_id, :status, :error)
          end
        end

        def build_success_response(sync_results)
          {
            success: true,
            message: "Sync initiated for #{sync_results.count} connections",
            results: sync_results
          }
        end
      end
    end
  end
end
