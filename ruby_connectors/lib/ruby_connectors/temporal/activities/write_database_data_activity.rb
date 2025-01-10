module RubyConnectors
  module Temporal
    module Activities
      class WriteDatabaseDataActivity < ::Temporal::Activity
        retry_policy(
          interval: 2,
          backoff: 2,
          max_attempts: 5
        )

        timeouts(
          start_to_close: 7200,
          schedule_to_close: 7500,
          schedule_to_start: 120,
          heartbeat: 600
        )

        def execute(params)
          params = params.transform_keys(&:to_s)
          workflow_store = Services::Redis::WorkflowStoreService.new
          total_records_written = 0
          
          begin
            1.upto(params["total_batches"].to_i) do |batch_number|
              activity.heartbeat
              redis_key = "#{params["workflow_id"]}:#{batch_number}"
              batch_data = workflow_store.get_workflow_data(redis_key)
              
              next if batch_data.nil? || batch_data["result"].nil?

              client ||= initialize_client(params)
              write_data(client, params, batch_data["result"]["records"])
              
              total_records_written += batch_data["result"]["records"].size
            end
            
            { 
              status: "success", 
              records_written: total_records_written
            }
          rescue StandardError => e
            ::Temporal.logger.error("WriteDataActivity failed: #{e.message}")
            {
              status: "error",
              error: e.message
            }
          end
        end

        private

        def initialize_client(params)
          connector_class = Object.const_get("RubyConnectors::#{params["connector_class_name"].capitalize}Connector::Client")
          connector_class.new(params["configuration"])
        end

        def write_data(client, params, records)
          client.write(
            records,
            table_name: params["stream_name"],
            schema: params["schema"]["table_schema"],
            schema_name: params["schema"]["schema_name"],
            database_name: params["schema"]["database"],
            primary_keys: params["primary_keys"]
          )
        end
      end
    end
  end
end
