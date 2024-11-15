# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class ApiStrategy < BaseStrategy
        def workflow_class
          "RubyConnectors::Temporal::Workflows::ReadApiDataWorkflow"
        end

        def build_params(sync:, page:, workflow_id:)
          super(sync: sync).merge(
            page: page,
            workflow_id: workflow_id
          ).as_json
        end
      end
    end
  end
end
