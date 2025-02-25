# frozen_string_literal: true

module RubyConnectors
  module Temporal
    module Activities
      class ReadDatabaseDataActivity < ::Temporal::Activity
        retry_policy(
          interval: 2,
          backoff: 2,
          max_attempts: 5
        )

        timeouts(
          start_to_close: 1800, # 30 minutes
          schedule_to_close: 2000,
          schedule_to_start: 120,
          heartbeat: 120
        )

        def execute(params)
          params = params.transform_keys(&:to_s)
          workflow_store = Services::Redis::WorkflowStoreService.new

          begin
            connector_class = Object.const_get("RubyConnectors::#{params["connector_class_name"].capitalize}Connector::Reader")
            reader = connector_class.new(params["configuration"])

            result = reader.read(
              query: params["query"],
              offset: params["offset"].to_i,
              limit: params["limit"].to_i
            )

            workflow_key = "#{params["parent_workflow_id"]}:#{params["offset"]}-#{params["limit"]}"
            workflow_store.store_workflow_data(workflow_key, result)

            { 
              status: "success", 
              workflow_id: params["workflow_id"],
              workflow_key: workflow_key,
              offset: params["offset"].to_i,
              limit: params["limit"].to_i,
              total_records: result[:total_records]
            }
          rescue StandardError => e
            ::Temporal.logger.error("ReadDatabaseDataActivity failed: #{e.message}")
            {
              workflow_id: params["workflow_id"],
              offset: params["offset"].to_i,
              error: e.message,
              status: "error"
            }
          end
        end
      end
    end
  end
end 