# frozen_string_literal: true

module Temporal
  module Workflows
    module Extractors
      class StartFirstPageWorkflow < ::Temporal::Workflow
        def execute(sync_run_id:, workflow_params:)
          workflow_id = "read_first_page_api_data_workflow-sync_run_id_#{sync_run_id}"
          first_page_workflow_params = workflow_params[:workflow_params].merge(workflow_id: workflow_id)

          run_id = Temporal.start_workflow(
            "RubyConnectors::Temporal::Workflows::ReadFirstPageApiDataWorkflow",
            first_page_workflow_params,
            options: { workflow_id: workflow_id, task_queue: "ruby_connectors_queue" }
          )

          { workflow_id: workflow_id, run_id: run_id, success: true }
        end
      end
    end
  end
end
