# frozen_string_literal: true

require "ruby_connectors"
require "vcr"
require "webmock"

# Load environment variables from .env file
Dotenv.load

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<GITHUB_ACCESS_TOKEN>") { ENV.fetch("GITHUB_ACCESS_TOKEN", nil) }
  config.filter_sensitive_data("<MOTHERDUCK_TOKEN>") { ENV.fetch("MOTHERDUCK_TOKEN", nil) }
  
  vcr_mode = ENV['VCR_MODE'] =~ /rec/i ? :all : :once
  config.default_cassette_options = {
    record: vcr_mode,
    match_requests_on: %i[method uri body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end