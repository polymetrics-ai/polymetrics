# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/github_connector/connection"
require "vcr"

RSpec.describe RubyConnectors::GithubConnector::Connection do
  subject { described_class.new(config) }

  let(:config) do
    {
      personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
      repository: "rails/rails"
    }
  end

  describe "#connect" do
    it "establishes a connection and returns true" do
      VCR.use_cassette("github/github_connect") do
        expect(subject.connect).to be true
      end
    end
  end
end
