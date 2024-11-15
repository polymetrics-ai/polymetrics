# frozen_string_literal: true

module Connections
  class StartDataSyncService
    def initialize(connection)
      @connection = connection
    end

    def call
      @connection.start!
      start_sync_workflow
    end

    private

    def start_sync_workflow
      workflow_id = generate_workflow_id
      Temporal.start_workflow(
        Temporal::Workflows::ConnectionDataSyncWorkflow,
        @connection.id,
        options: workflow_options(workflow_id)
      )
    end

    def workflow_options(workflow_id)
      {
        workflow_id: workflow_id,
        task_queue: "platform_queue",
        workflow_execution_timeout: 86_400 # 24 hours
      }
    end

    def generate_workflow_id
      "connection_data_sync_#{@connection.id}_#{SecureRandom.uuid}"
    end
  end
end
