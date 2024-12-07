# frozen_string_literal: true

require "redis"

def initialize_redis
  Redis.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    ssl_params: ssl_params,
    timeout: ENV.fetch("REDIS_TIMEOUT", 1).to_i,
    reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 3).to_i
  )
rescue Redis::BaseError => e
  Rails.logger.error("Failed to initialize Redis client: #{e.message}")
  raise
end

private

def ssl_params
  return {} unless ENV["REDIS_USE_SSL"]

  {
    ssl: true,
    ssl_verify: true
  }
end
