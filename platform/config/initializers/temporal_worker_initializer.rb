# frozen_string_literal: true

# require "concurrent"

# Rails.application.config.after_initialize do
#   pool = Concurrent::FixedThreadPool.new(1)

#   pool.post do
#     TemporalWorker.start
#   rescue StandardError => e
#     Rails.logger.error "Temporal worker error: #{e.message}"
#     Rails.logger.error e.backtrace.join("\n")
#   end

#   at_exit do
#     pool.shutdown
#     pool.wait_for_termination
#   end
# end
