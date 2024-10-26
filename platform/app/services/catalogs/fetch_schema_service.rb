# frozen_string_literal: true

module Catalogs
  class FetchSchemaService
    def initialize(connector_class_name)
      @connector_class_name = connector_class_name
    end

    def call
      workflow_id = generate_workflow_id
      run_id = start_workflow(workflow_id)
      await_workflow_result(workflow_id, run_id)
    end

    private

    def generate_workflow_id
      "fetch_schema_#{@connector_class_name}_#{Time.now.to_i}"
    end

    def start_workflow(workflow_id)
      Temporal.start_workflow(
        "RubyConnectors::Temporal::Workflows::FetchSchemaWorkflow",
        @connector_class_name,
        options: workflow_options(workflow_id)
      )
    end

    def workflow_options(workflow_id)
      {
        task_queue: "ruby_connectors_queue",
        workflow_id: workflow_id,
        workflow_execution_timeout: 30
      }
    end

    def await_workflow_result(workflow_id, run_id)
      Temporal.await_workflow_result(
        "RubyConnectors::Temporal::Workflows::FetchSchemaWorkflow",
        workflow_id: workflow_id,
        run_id: run_id,
        timeout: 25
      )
    end
  end
end
