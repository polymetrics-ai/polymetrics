# frozen_string_literal: true

require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<GITHUB_ACCESS_TOKEN>") { ENV.fetch("GITHUB_ACCESS_TOKEN", nil) }
end
