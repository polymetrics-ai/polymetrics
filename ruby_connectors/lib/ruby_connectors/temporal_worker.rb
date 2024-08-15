# frozen_string_literal: true

module RubyConnectors
  class TemporalWorker
    def self.start
      ::Temporal.configure do |config|
        config.host = ENV["TEMPORAL_HOST"] || "localhost"
        config.port = ENV["TEMPORAL_PORT"] || 7233
        config.namespace = ENV["TEMPORAL_NAMESPACE"] || "polymetrics-dev"
        config.task_queue = "ruby_connectors_queue"
      end

      def Temporal.warn(msg)
        Rails.logger.warn(msg)
      end

      begin
        ::Temporal.register_namespace("polymetrics-dev", "Temporal Namespace for Polymetrics")
      rescue ::Temporal::NamespaceAlreadyExistsFailure
        nil # service was already registered
      end

      worker = ::Temporal::Worker.new

      # Register workflows here
      worker.register_workflow(RubyConnectors::Temporal::Workflows::ConnectionStatusWorkflow)

      # Register activities here
      worker.register_activity(RubyConnectors::Temporal::Activities::ConnectionStatusActivity)

      worker.start
    end
  end
end
