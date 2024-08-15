# frozen_string_literal: true

require "octokit"
require "byebug"
require "temporal"
require "temporal/worker"
require "sequel"
require "pg"
require "active_support/all"
require "dotenv/load"

require_relative "ruby_connectors/version"
require_relative "ruby_connectors/temporal_worker"
require_relative "ruby_connectors/temporal/workflows/connection_status_workflow"
require_relative "ruby_connectors/temporal/activities/connection_status_activity"

Dir[File.join(__dir__, "ruby_connectors", "**", "*.rb")].each { |file| require file }

module RubyConnectors
  DB = Sequel.connect(adapter: :postgres, host: "localhost", port: 5432,
                      database: "platform_development", max_connections: 10)

  class Error < StandardError; end
end
