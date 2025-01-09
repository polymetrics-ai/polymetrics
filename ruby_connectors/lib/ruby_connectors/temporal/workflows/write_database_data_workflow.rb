module RubyConnectors
  module Temporal
    module Workflows
      class WriteDatabaseDataWorkflow < ::Temporal::Workflow
        def execute(params)
          initialize_workflow_state(params)
          
          begin
            @result = write_data
            @result = @result.is_a?(Hash) ? @result.with_indifferent_access : {}
            
            signal_completion if @result[:status] == "success"
            
            { 
              status: @result[:status], 
              records_written: @result[:records_written] || 0,
              error: @result[:error]
            }
          rescue StandardError => e
            {
              status: "error",
              records_written: 0,
              error: e.message
            }
          end
        end

        private

        def initialize_workflow_state(params)
          @input = params.transform_keys(&:to_s)
        end

        def write_data
          Activities::WriteDatabaseDataActivity.execute!(@input)
        end

        def signal_completion
          ::Temporal.signal_workflow(
            "Temporal::Workflows::Loaders::DatabaseDataLoaderWorkflow",
            "database_write_completed",
            @input["database_data_loader_workflow_id"],
            @input["database_data_loader_workflow_run_id"],
            {
              status: "success",
              workflow_id: @input["workflow_id"],
              total_batches: @input["total_batches"]
            }
          )
        end
      end
    end
  end
end
