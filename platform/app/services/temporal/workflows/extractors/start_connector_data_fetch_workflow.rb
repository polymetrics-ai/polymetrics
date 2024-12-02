# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      class StartConnectorDataFetchWorkflow < ::Temporal::Workflow
        timeouts(
          execution: 3600, # 1 hour
          run: 3000,       # 50 minutes
          task: 300        # 5 minutes
        )

        def execute(workflow_params)
          start_child_workflow(workflow_params)
        rescue Temporal::WorkflowExecutionAlreadyStartedFailure => e
          handle_already_running_workflow(workflow_params, e)
        rescue StandardError => e
          handle_error(workflow_params, e)
        end

        private

        def start_child_workflow(workflow_params)
          child_workflow_run_id = start_temporal_workflow(workflow_params)
          build_success_response(workflow_params, child_workflow_run_id)
        end

        def start_temporal_workflow(workflow_params)
          # TODO: Change logic for workflow params
          Temporal.start_workflow(
            workflow_params[:workflow_class],
            workflow_params[:workflow_params],
            options: build_workflow_options(workflow_params)
          )
        end

        def build_workflow_options(workflow_params)
          {
            workflow_id: workflow_params[:workflow_options][:workflow_id],
            task_queue: workflow_params[:workflow_options][:task_queue],
            parent_close_policy: :abandon
          }
        end

        def build_success_response(workflow_params, run_id)
          {
            success: true,
            workflow_id: workflow_params[:workflow_options][:workflow_id],
            run_id: run_id
          }
        end

        def handle_already_running_workflow(workflow_params, error)
          workflow.logger.info(
            "Workflow already running",
            workflow_id: workflow_params[:workflow_options][:workflow_id],
            message: error.message
          )

          { success: true, message: "Workflow already running" }
        end

        def handle_error(workflow_params, error)
          workflow.logger.error(
            "Failed to start child workflow",
            workflow_id: workflow_params[:workflow_options][:workflow_id],
            error: error.message
          )

          { success: false, error: error.message }
        end
      end
    end
  end
end
