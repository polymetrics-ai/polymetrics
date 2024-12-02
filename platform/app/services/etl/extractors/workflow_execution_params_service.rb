# frozen_string_literal: true

module Etl
  module Extractors
    class WorkflowExecutionParamsService
      WORKFLOW_TIMEOUT = 30

      def initialize(sync_run:, options: {})
        @sync_run = sync_run
        @sync = sync_run.sync
        @options = options
        @workflow_id = generate_workflow_id
        @options[:workflow_id] = @workflow_id
        @workflow_strategy = workflow_strategy_for(@sync.connection.source.integration_type)
      end

      def call
        {
          workflow_class: @workflow_strategy.workflow_class,
          workflow_params: workflow_params,
          workflow_options: workflow_options
        }
      rescue StandardError => e
        log_error(e, {})
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

      def workflow_params
        @workflow_strategy.build_params(
          sync_run: @sync_run,
          **@options
        )
      end

      def workflow_options
        @workflow_strategy.workflow_options(@sync_run).merge(
          workflow_id: @workflow_id
        )
      end

      def generate_workflow_id
        "read_data_sync_id_#{@sync.id}_sync_run_id_#{@sync_run.id}"
      end

      def handle_workflow_error(error)
        ::Activities::SyncLogActivity.execute!(
          sync_run_id: @sync_run_id,
          message: error.message,
          log_type: :error
        )
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
