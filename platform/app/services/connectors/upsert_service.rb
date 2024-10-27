# frozen_string_literal: true

module Connectors
  class UpsertService
    attr_reader :params, :current_user, :connector

    def initialize(params, current_user, connector = nil)
      @params = params
      @current_user = current_user
      @connector = connector
    end

    def call
      @connector ? update : create
    end

    private

    def create
      execute_workflow
    end

    def update
      configuration_changed? ? execute_workflow : update_connector
    end

    def execute_workflow
      workflow_id = generate_workflow_id
      run_id = start_workflow(workflow_id)
      result = await_workflow_result(workflow_id, run_id)
      process_result(result)
    end

    def generate_workflow_id
      components = [@current_user.id, @params[:workspace_id], @params[:name], @params[:connector_class_name]]
      Digest::SHA256.hexdigest(components.join("-"))
    end

    def start_workflow(workflow_id)
      Temporal.start_workflow(
        "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
        @params.as_json,
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
        "RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow",
        workflow_id: workflow_id,
        run_id: run_id,
        timeout: 25
      )
    end

    def process_result(result)
      if result[:connected]
        save_or_update_connector
      else
        error_message = result[:error_message]
        raise StandardError, error_message || "Please check your configuration and try again."
      end
    end

    def save_or_update_connector
      connector_params = @params.merge(workspace_id: current_user.workspace_ids.first, connected: true)

      if @connector
        update_existing_connector(connector_params)
      else
        create_new_connector(connector_params)
      end
    end

    def update_existing_connector(connector_params)
      @connector.update!(connector_params)
      @connector
    end

    def create_new_connector(connector_params)
      Connector.create!(connector_params.as_json)
    end

    def update_connector
      @connector.update!(@params)
      @connector
    end

    def configuration_changed?
      @params[:configuration] != @connector.configuration
    end
  end
end
