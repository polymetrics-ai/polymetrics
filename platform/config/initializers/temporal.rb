# frozen_string_literal: true

Temporal.configure do |config|
  config.host = ENV["TEMPORAL_HOST"] || "localhost"
  config.port = ENV["TEMPORAL_PORT"] || 7233
  config.namespace = ENV["TEMPORAL_NAMESPACE"] || "polymetrics-dev"
end

def Temporal.warn(msg)
  Rails.logger.warn(msg)
end
