# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/github_connector/connection"

RSpec.describe RubyConnectors::GithubConnector::Connection do
  subject { described_class.new(config) }

  let(:config) do
    {
      personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
      repository: "rails/rails"
    }
  end

  describe "#connect", :vcr do
    it "checks the connection status" do
      expect(subject.connect).to be true
    end
  end
end
