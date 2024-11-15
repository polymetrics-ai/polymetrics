# frozen_string_literal: true

module Temporal
  module Workflows
    class ConnectionDataSyncWorkflow < ::Temporal::Workflow
      def execute(connection_id)
        @connection = ::Connection.find(connection_id)

        begin
          Activities::StartSyncWorkflowsActivity.execute!(connection_id)
        rescue StandardError => e
          @connection.fail!
          log_error(e)
        end
      end

      private

      def log_error(error)
        Rails.logger.error("Connection sync failed for connection #{@connection.id}: #{error.message}")
      end
    end
  end
end
