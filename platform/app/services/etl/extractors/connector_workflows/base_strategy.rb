# frozen_string_literal: true

module Etl
  module Extractors
    module ConnectorWorkflows
      class BaseStrategy
        LANGUAGE_TASK_QUEUES = {
          ruby: "ruby_connectors_queue",
          python: "python_connectors_queue",
          javascript: "javascript_connectors_queue"
        }.freeze

        def workflow_class
          raise NotImplementedError
        end

        def build_params(sync_run:, **_options)
          {
            connector_class_name: sync_run.sync.connection.source.connector_class_name,
            configuration: sync_run.sync.connection.source.configuration,
            stream_name: sync_run.sync.stream_name
          }.as_json
        end

        def workflow_options(sync_run)
          {
            task_queue: task_queue_for(sync_run.sync.connection.source.connector_language)
          }
        end

        private

        def task_queue_for(language)
          return LANGUAGE_TASK_QUEUES[:ruby] if language.nil?

          LANGUAGE_TASK_QUEUES[language.to_sym] || LANGUAGE_TASK_QUEUES[:ruby]
        end
      end
    end
  end
end
