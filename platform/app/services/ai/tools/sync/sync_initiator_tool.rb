# frozen_string_literal: true

module Ai
  module Tools
    module Sync
      class SyncInitiatorTool < BaseTool
        define_function(
          :initiate_sync,
          description: "Initiates data synchronization for a connection"
        ) do
          property :connection_id,
                   type: "string",
                   description: "ID of the connection to sync",
                   required: true
        end

        def initialize(workspace_id:, chat_id:)
          @workspace_id = workspace_id
          @chat_id = chat_id
          @chat = Chat.find(@chat_id)
        end

        def initiate_sync(connection_id:)
          connection = ::Connection.find(connection_id)
          return if connection.running?

          connection_workflow_run_id = Connections::StartDataSyncService.new(connection).call

          create_sync_pipeline_action(connection, connection_workflow_run_id)
          build_success_response(connection, connection_workflow_run_id)
        rescue StandardError => e
          handle_error(e.message)
        end

        private

        def create_sync_pipeline_action(connection, connection_workflow_run_id)
          pipeline_message = @chat.messages.pipeline.last
          return unless pipeline_message&.pipeline

          pipeline = pipeline_message.pipeline
          next_position = pipeline.pipeline_actions.maximum(:position).to_i + 1

          pipeline.pipeline_actions.create!(
            action_type: :sync_initialization,
            position: next_position,
            action_data: {
              connection_id: connection.id,
              connection_workflow_run_id: connection_workflow_run_id
            }
          )
        end

        def build_success_response(connection, connection_workflow_run_id)
          {
            success: true,
            message: "Sync initiated for connection #{connection.id}",
            connection_workflow_run_id: connection_workflow_run_id
          }
        end
      end
    end
  end
end
