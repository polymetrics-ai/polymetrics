# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/github_connector/client"

RSpec.describe RubyConnectors::GithubConnector::Client do
  subject { described_class.new(config) }

  let(:config) do
    {
      personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
      repository: "rails/rails"
    }
  end

  describe "#connect", :vcr do
    it "establishes a connection and returns true" do
      expect(subject.connect).to be true
    end
  end

  # describe '#read', :vcr do
  #   it 'reads data from the repository' do
  #     # Assuming the read method fetches some data
  #     expect(subject.read).not_to be_nil
  #   end
  # end

  # describe '#write', :vcr do
  #   it 'writes data to the repository' do
  #     data = { key: 'value' }
  #     expect { subject.write(data) }.not_to raise_error
  #   end
  # end
end
