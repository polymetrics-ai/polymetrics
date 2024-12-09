# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class DatabaseStrategy < BaseStrategy
        def workflow_class
          "RubyConnectors::Temporal::Workflows::DatabaseReadDataWorkflow"
        end

        def build_params(sync_run:, **options)
          super(sync_run: sync_run).merge(
            batch_size: options[:batch_size] || sync_run.sync.connection.source.configuration["batch_size"],
            query_timeout: sync_run.sync.connection.source.configuration["query_timeout"]
          ).as_json
        end
      end
    end
  end
end
