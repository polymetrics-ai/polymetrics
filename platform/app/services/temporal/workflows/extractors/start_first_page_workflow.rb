# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      class StartFirstPageWorkflow < ::Temporal::Workflow
        def execute(sync_run_id:, workflow_params:)
          validate_params(sync_run_id, workflow_params)
          start_first_page_workflow(sync_run_id, workflow_params)
        end

        private

        def validate_params(sync_run_id, workflow_params)
          raise ArgumentError, "sync_run_id cannot be nil" if sync_run_id.nil?
          raise ArgumentError, "workflow_params cannot be nil" if workflow_params.nil?
          raise ArgumentError, "workflow_params must be a Hash" unless workflow_params.is_a?(Hash)
        end

        def start_first_page_workflow(sync_run_id, workflow_params)
          workflow_id = "read_first_page_api_data_workflow-sync_run_id_#{sync_run_id}"
          first_page_workflow_params = prepare_workflow_params(workflow_params, workflow_id)

          begin
            run_id = start_temporal_workflow(workflow_id, first_page_workflow_params)
            { workflow_id: workflow_id, run_id: run_id, success: true }
          rescue KeyError => e
            handle_key_error(workflow_id, e)
          rescue StandardError => e
            handle_standard_error(workflow_id, e)
          end
        end

        def prepare_workflow_params(workflow_params, workflow_id)
          workflow_params.fetch(:workflow_params) { {} }
                         .merge(workflow_id: workflow_id)
        end

        def start_temporal_workflow(workflow_id, params)
          Temporal.start_workflow(
            "RubyConnectors::Temporal::Workflows::ReadFirstPageApiDataWorkflow",
            params,
            options: {
              workflow_id: workflow_id,
              task_queue: ENV.fetch("TEMPORAL_TASK_QUEUE", "ruby_connectors_queue")
            }
          )
        end

        def handle_key_error(workflow_id, error)
          workflow.logger.error("Invalid workflow_params structure: #{error.message}")
          { workflow_id: workflow_id, error: "Invalid workflow parameters", success: false }
        end

        def handle_standard_error(workflow_id, error)
          workflow.logger.error("Failed to start workflow: #{error.message}")
          { workflow_id: workflow_id, error: error.message, success: false }
        end
      end
    end
  end
end
