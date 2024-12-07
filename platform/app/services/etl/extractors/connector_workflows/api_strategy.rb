# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class ApiStrategy < BaseStrategy
        def workflow_class
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow"
        end

        def build_params(sync_run:, **options)
          super(sync_run: sync_run).merge(
            page: sync_run.current_page || 1,
            workflow_id: options[:workflow_id]
          ).as_json
        end
      end
    end
  end
end
