# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connections::CreateService do
  let(:workspace) { create(:workspace) }
  let(:source_connector) { create(:connector, workspace: workspace) }
  let(:destination_connector) { workspace.default_analytics_db }
  let(:streams) { %w[stream1 stream2] }
  let(:service) { described_class.new(source_connector.id, streams) }

  describe "#call" do
    it "creates a new connection" do
      expect { service.call }.to change(Connection, :count).by(1)
    end

    it "returns the id of the created connection" do
      connection_id = service.call
      expect(connection_id).to be_a(Integer)
      expect(Connection.find(connection_id)).to be_present
    end

    it "sets the correct attributes for the connection" do
      connection_id = service.call
      connection = Connection.find(connection_id)

      expect(connection).to have_attributes(
        workspace: workspace,
        source: source_connector,
        destination: destination_connector,
        name: "#{source_connector.name}_#{Digest::SHA256.hexdigest(streams.join("-"))[0..15]} Connection",
        schedule_type: "manual",
        status: "created",
        sync_frequency: "hourly",
        namespace: "system_defined"
      )
    end

    it "sets the correct configuration for the connection" do
      connection_id = service.call
      connection = Connection.find(connection_id)

      expect(connection.configuration).to eq(
        {
          "source" => source_connector.configuration,
          "destination" => destination_connector.configuration
        }
      )
    end

    context "when streams are not provided" do
      let(:service) { described_class.new(source_connector.id) }

      it "creates a connection with default name" do
        connection_id = service.call
        connection = Connection.find(connection_id)
        expect(connection.name).to eq("#{source_connector.name} Connection")
      end
    end

    context "when the connector is not found" do
      let(:service) { described_class.new(-1) }

      it "raises an ActiveRecord::RecordNotFound error" do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when default analytics db is not set" do
      before do
        # Clear any existing default analytics DB
        workspace.connectors.update_all(default_analytics_db: false)
        workspace.reload
      end

      it "raises an error" do
        expect { service.call }.to raise_error("Default analytics database not configured")
      end
    end

    describe "#connection_configuration" do
      it "returns the correct configuration hash" do
        config = service.send(:connection_configuration)
        expect(config).to eq(
          {
            source: source_connector.configuration,
            destination: destination_connector.configuration
          }
        )
      end
    end
  end
end
