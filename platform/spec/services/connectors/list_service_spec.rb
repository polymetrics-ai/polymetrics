# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::ListService do
  describe "#call" do
    subject(:service_call) { service.call }

    let(:service) { described_class.new }
    let(:yaml_content) do
      {
        "connectors" => [
          {
            "name" => "Connector1",
            "integration_type" => "api",
            "language" => "ruby",
            "class_name" => "Connector1Class",
            "operations" => ["read"],
            "definition_status" => "active",
            "version" => "1.0.0",
            "maintainer" => "Team A"
          },
          {
            "name" => "Connector2",
            "integration_type" => "database",
            "language" => "python",
            "class_name" => "Connector2Class",
            "operations" => ["write"],
            "definition_status" => "beta",
            "version" => "0.9.0",
            "maintainer" => "Team B"
          }
        ]
      }
    end

    let(:connection_specification) do
      {
        "name" => "Connector1",
        "description" => "This is a test connector"
      }
    end

    before do
      allow(YAML).to receive(:load_file).and_return(yaml_content)
      allow(File).to receive_messages(exist?: true, read: connection_specification.to_json)
    end

    it "returns an array of connector definitions" do
      expect(service_call).to be_an(Array)
      expect(service_call.size).to eq(2)
    end

    it "correctly maps connector attributes" do
      expect(service_call.first).to include(
        name: "Connector1",
        integration_type: "api",
        language: "ruby",
        class_name: "Connector1Class"
      )
    end

    it "correctly maps additional connector attributes" do
      expect(service_call.first).to include(
        operations: ["read"],
        definition_status: "active",
        version: "1.0.0",
        maintainer: "Team A"
      )
    end

    it "loads the YAML file from the correct path" do
      service_call
      expect(YAML).to have_received(:load_file).with(Rails.root.join("config/connectors.yml"))
    end

    it "includes name and description in the connection specification" do
      expect(service_call.first).to include(
        connection_specification: include(
          "name" => "Connector1",
          "description" => "This is a test connector"
        )
      )
    end
  end
end
