# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class DatabaseStrategy < BaseStrategy
        def workflow_class
          "RubyConnectors::Temporal::Workflows::DatabaseReadDataWorkflow"
        end

        def build_params(sync_run:, batch_size: nil)
          super(sync_run: sync_run).merge(
            batch_size: batch_size || sync_run.sync.connection.source.batch_size,
            query_timeout: sync_run.sync.connection.source.query_timeout
          ).as_json
        end
      end
    end
  end
end
