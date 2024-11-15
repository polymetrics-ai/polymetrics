# frozen_string_literal: true

module Etl
  module Extractors
    class WorkflowExecutionService
      WORKFLOW_TIMEOUT = 30

      def initialize(sync:, options: {})
        @sync = sync
        @options = options
        @workflow_id = options[:workflow_id] || generate_workflow_id
        @workflow_store = Redis::WorkflowStoreService.new
        @workflow_strategy = workflow_strategy_for(@sync.connection.source.integration_type)
      end

      def execute
        run_id = start_workflow
        result = await_workflow_result(run_id)
        process_workflow_result(result)
      rescue StandardError => e
        handle_workflow_error(run_id, e)
      end

      private

      def workflow_strategy_for(integration_type)
        case integration_type.to_sym
        when :api
          ConnectorWorkflows::ApiStrategy.new
        when :database
          ConnectorWorkflows::DatabaseStrategy.new
        else
          raise UnsupportedIntegrationType, "Unsupported integration type: #{integration_type}"
        end
      end

      def start_workflow
        Temporal.start_workflow(
          @workflow_strategy.workflow_class,
          workflow_params,
          options: workflow_options
        )
      end

      def workflow_params
        @workflow_strategy.build_params(
          sync: @sync,
          **@options
        )
      end

      def workflow_options
        @workflow_strategy.workflow_options(@sync).merge(
          workflow_id: @workflow_id,
          workflow_execution_timeout: WORKFLOW_TIMEOUT
        )
      end

      def generate_workflow_id
        "#{@sync.connection.source.integration_type}_#{@sync.id}_#{SecureRandom.uuid}"
      end

      def await_workflow_result(run_id)
        Temporal.await_workflow_result(
          @workflow_strategy.workflow_class,
          workflow_id: @workflow_id,
          run_id: run_id,
          timeout: WORKFLOW_TIMEOUT
        )
      end

      def process_workflow_result(result)
        case result[:status]
        when "success"
          handle_successful_result(result)
        when "error"
          handle_error_result(result)
        else
          handle_unknown_result(result)
        end
      end

      def handle_successful_result(result)
        workflow_data = @workflow_store.get_workflow_data(@workflow_id)
        payload = workflow_data&.dig(:result) || result[:data]
        Result.success(payload)
      end

      def handle_error_result(result)
        error_message = result[:error] || "Unknown workflow error"
        Result.failure(WorkflowExecutionError.new(error_message))
      end

      def handle_unknown_result(result)
        Result.failure(
          WorkflowExecutionError.new("Unknown result status: #{result[:status]}")
        )
      end

      def handle_workflow_error(run_id, error)
        terminate_workflow(run_id) if run_id
        Result.failure(error)
      end

      def terminate_workflow(run_id)
        Temporal.terminate_workflow(
          @workflow_id,
          run_id: run_id,
          namespace: workflow_namespace
        )
      rescue StandardError => e
        Rails.logger.error("Failed to terminate workflow: #{e.message}")
      end

      def workflow_namespace
        ENV["TEMPORAL_NAMESPACE"] || "default-namespace"
      end

      def log_error(error, context = {})
        Rails.logger.error(
          "Workflow execution error: #{error.message}",
          workflow_id: @workflow_id,
          sync_id: @sync.id,
          connector_type: @sync.connection.source.connector_type,
          **context
        )
      end
    end
  end
end
