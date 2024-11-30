# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      class StartConnectorDataFetchWorkflow < ::Temporal::Workflow
        timeouts(
          execution: 3600,  # 1 hour
          run: 3000,       # 50 minutes
          task: 300        # 5 minutes
        )

        def execute(workflow_params)
          begin
            child_workflow_run_id = Temporal.start_workflow(
              workflow_params[:workflow_class],
              workflow_params[:workflow_params],
              options: {
                workflow_id: workflow_params[:workflow_options][:workflow_id],
                task_queue: workflow_params[:workflow_options][:task_queue],
                parent_close_policy: :abandon
              }
            )

            {
              success: true,
              workflow_id: workflow_params[:workflow_options][:workflow_id],
              run_id: child_workflow_run_id
            }
          rescue Temporal::WorkflowExecutionAlreadyStartedFailure => e
            workflow.logger.info("Workflow already running", {
              workflow_id: workflow_params[:workflow_options][:workflow_id],
              message: e.message
            })
            
            { success: true, message: "Workflow already running" }
          rescue StandardError => e
            workflow.logger.error("Failed to start child workflow", {
              workflow_id: workflow_params[:workflow_options][:workflow_id],
              error: e.message
            })
            
            { success: false, error: e.message }
          end
        end
      end
    end
  end
end 