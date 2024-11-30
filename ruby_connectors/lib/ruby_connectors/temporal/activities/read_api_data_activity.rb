module RubyConnectors
  module Temporal
    module Activities
      class ReadApiDataActivity < ::Temporal::Activity
        retry_policy(
          interval: 2,
          backoff: 2,
          max_attempts: 5
        )

        timeouts(
          start_to_close: 1800,  # 30 minutes in seconds
          schedule_to_close: 2000,  # ~33 minutes
          schedule_to_start: 120,   # 2 minutes
          heartbeat: 120           # 2 minutes
        )

        def execute(params)
          params = params.transform_keys(&:to_s)
          workflow_store = Services::Redis::WorkflowStoreService.new
          
          begin
            connector_class = Object.const_get("RubyConnectors::#{params['connector_class_name'].capitalize}Connector::Reader")
            reader = connector_class.new(params['configuration'])
            
            result = reader.read(params['stream_name'], params['page'])
            workflow_store.store_workflow_data(params['workflow_id'], result)
            
            { status: 'success', workflow_id: params['workflow_id'], total_pages: result[:total_pages], page_number: params['page'].to_i }
          rescue StandardError => e
            ::Temporal.logger.error("ReadDataActivity failed: #{e.message}")
            
            {
              workflow_id: params['workflow_id'],
              current_page: params['page'].to_i,
              error: e.message,
              status: 'error'
            }
          end
        end
      end
    end
  end
end 