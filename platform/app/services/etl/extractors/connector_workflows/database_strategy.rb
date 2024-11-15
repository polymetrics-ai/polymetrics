# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class DatabaseStrategy < BaseStrategy
        def workflow_class
          "RubyConnectors::Temporal::Workflows::DatabaseReadDataWorkflow"
        end

        def build_params(sync:, batch_size: nil)
          super(sync: sync).merge(
            batch_size: batch_size || sync.connection.source.batch_size,
            query_timeout: sync.connection.source.query_timeout
          ).as_json
        end
      end
    end
  end
end
