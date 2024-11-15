module RubyConnectors
  module Temporal
    module Activities
      class ReadApiDataActivity < ::Temporal::Activity
        def execute(params)
          params = params.transform_keys(&:to_s)
          workflow_store = Services::Redis::WorkflowStoreService.new
          
          begin
            connector_class = Object.const_get("RubyConnectors::#{params['connector_class_name'].capitalize}Connector::Reader")
            reader = connector_class.new(params['configuration'])
            
            result = reader.read(params['stream_name'], params['page'])
            workflow_store.store_workflow_data(params['workflow_id'], result)
            
            { status: 'success', workflow_id: params['workflow_id'] }
          rescue StandardError => e
            ::Temporal.logger.error("ReadDataActivity failed: #{e.message}")
            
            error_result = {
              workflow_id: params['workflow_id'],
              current_page: params['page'].to_i,
              error: e.message,
              status: 'error'
            }

            error_result
          end
        end
      end
    end
  end
end 