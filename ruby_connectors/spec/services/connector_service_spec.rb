# frozen_string_literal: true

require "spec_helper"
require "ruby_connectors/services/connector_service"

RSpec.describe RubyConnectors::Services::ConnectorService do
  let(:connector) do
    {
      connector_class_name: "github",
      configuration: {
        personal_access_token: ENV.fetch("GITHUB_ACCESS_TOKEN", nil),
        repository: "rails/rails"
      }
    }
  end

  describe ".connect_and_fetch_status" do
    it "calls connect_to_connector with the connector" do
      VCR.use_cassette("connector_service/connector_service_connect_and_fetch_status") do
        allow(described_class).to receive(:connect_to_connector).and_return({ connected: true })
        result = described_class.connect_and_fetch_status(connector)

        expect(described_class).to have_received(:connect_to_connector).with(connector)
        expect(result).to eq({ connected: true })
      end
    end
  end

  describe ".connect_to_connector" do
    context "when the connection is successful" do
      it "returns a hash with connected status" do
        VCR.use_cassette("github/github_connect") do
          result = described_class.connect_to_connector(connector)
          expect(result).to eq({ connected: true })
        end
      end
    end

    context "when an error occurs" do
      before do
        allow(Object).to receive(:const_get).with("RubyConnectors::GithubConnector::Client").and_raise(StandardError.new("Connection error"))
      end

      it "returns a hash with connected status as false and error message" do
        VCR.use_cassette("connector_service/connector_service_failed_connection") do
          result = described_class.connect_to_connector(connector)
          expect(result).to eq({ connected: false, error_message: "Connection error" })
        end
      end
    end
  end
end
