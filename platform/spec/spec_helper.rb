# frozen_string_literal: true

# spec/spec_helper.rb
require "factory_bot"
require "faker"
require "shoulda/matchers"
require "webmock/rspec"
require "vcr"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.reload
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Allow localhost requests for API endpoints
  config.ignore_hosts "localhost", "127.0.0.1"

  # Filter sensitive data
  config.filter_sensitive_data("<TEMPORAL_HOST>") { ENV.fetch("TEMPORAL_HOST", nil) }
  config.filter_sensitive_data("<TEMPORAL_PORT>") { ENV.fetch("TEMPORAL_PORT", nil) }
  config.filter_sensitive_data("<TEMPORAL_NAMESPACE>") { ENV.fetch("TEMPORAL_NAMESPACE", nil) }
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV.fetch("GITHUB_ACCESS_TOKEN", nil) }
  config.filter_sensitive_data("<OPENROUTER_API_KEY>") { ENV.fetch("OPENROUTER_API_KEY", nil) }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV.fetch("OPENAI_API_KEY", nil) }

  # Filter JWT token from Authorization header
  config.filter_sensitive_data("<AUTH_TOKEN>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header&.gsub(/^Bearer\s+/, "")
  end

  # Configure GitHub API endpoint
  config.filter_sensitive_data("<GITHUB_API>") { "https://api.github.com" }

  # Default cassette options
  config.default_cassette_options = {
    record: ENV["VCR_RECORD"] ? :all : :once,
    match_requests_on: %i[method uri body],
    allow_unused_http_interactions: false
  }
end
