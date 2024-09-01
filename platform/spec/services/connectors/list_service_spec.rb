# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connectors::ListService do
  describe "#call" do
    let(:service) { described_class.new }
    let(:yaml_content) do
      {
        "connectors" => [
          {
            "name" => "Connector1",
            "type" => "source",
            "language" => "ruby",
            "class_name" => "Connector1Class",
            "operations" => ["read"],
            "status" => "active",
            "version" => "1.0.0",
            "maintainer" => "Team A"
          },
          {
            "name" => "Connector2",
            "type" => "destination",
            "language" => "python",
            "class_name" => "Connector2Class",
            "operations" => ["write"],
            "status" => "beta",
            "version" => "0.9.0",
            "maintainer" => "Team B"
          }
        ]
      }
    end

    before do
      allow(YAML).to receive(:load_file).and_return(yaml_content)
    end

    it "returns an array of connector definitions" do
      result = service.call
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it "correctly maps connector attributes" do
      result = service.call
      expect(result.first).to include(
        name: "Connector1",
        type: "source",
        language: "ruby",
        class_name: "Connector1Class"
      )
    end

    it "correctly maps additional connector attributes" do
      result = service.call
      expect(result.first).to include(
        operations: ["read"],
        status: "active",
        version: "1.0.0",
        maintainer: "Team A"
      )
    end

    it "loads the YAML file from the correct path" do
      service.call
      expect(YAML).to have_received(:load_file).with(Rails.root.join("config/connectors.yml"))
    end
  end
end
