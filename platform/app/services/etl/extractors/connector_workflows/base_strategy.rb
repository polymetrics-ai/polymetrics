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

        def build_params(sync:, **_options)
          {
            connector_class_name: sync.connection.source.connector_class_name,
            configuration: sync.connection.source.configuration,
            stream_name: sync.stream_name
          }.as_json
        end

        def workflow_options(sync)
          {
            task_queue: task_queue_for(sync.connection.source.connector_language),
            retry_policy: default_retry_policy
          }
        end

        private

        def task_queue_for(language)
          LANGUAGE_TASK_QUEUES[language.to_sym] || LANGUAGE_TASK_QUEUES[:ruby]
        end

        def default_retry_policy
          {
            interval: 1,
            backoff: 2,
            max_interval: 10,
            max_attempts: 3
          }
        end
      end
    end
  end
end
