# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connector, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workspace) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:connector_class_name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:connector_language) }
    it { is_expected.to validate_presence_of(:integration_type) }

    it { is_expected.to define_enum_for(:connector_language).with_values(ruby: 0, python: 1, javascript: 2) }
    it { is_expected.to define_enum_for(:integration_type).with_values(database: 0, api: 1) }

    describe "name uniqueness" do
      before do
        create(:connector, workspace: workspace, name: "Existing Connector", configuration: { key: "value" })
      end

      let(:workspace) { create(:workspace) }

      it "validates uniqueness of name scoped to workspace_id and configuration" do
        new_connector = build(:connector, workspace: workspace, name: "Existing Connector",
                                          configuration: { key: "value" })
        error_message = "Existing Connector already exists for this workspace with the same configuration. " \
                        "Please change the name or configuration."
        expect(new_connector).not_to be_valid
        expect(new_connector.errors[:name]).to include(error_message)
      end

      it "allows same name with different configuration" do
        new_connector = build(:connector, workspace: workspace, name: "Existing Connector",
                                          configuration: { key: "different_value" })
        expect(new_connector).to be_valid
      end

      it "allows same name in different workspace" do
        different_workspace = create(:workspace)
        new_connector = build(:connector, workspace: different_workspace, name: "Existing Connector",
                                          configuration: { key: "value" })
        expect(new_connector).to be_valid
      end
    end

    describe "#only_one_default_analytics_db_per_workspace" do
      let(:workspace) { create(:workspace) }
      let!(:existing_default_connector) do
        create(:connector, workspace: workspace, integration_type: :database, default_analytics_db: true)
      end

      context "when setting a new database connector as default" do
        it "is valid if no other default exists" do
          existing_default_connector.update(default_analytics_db: false)
          new_connector = build(:connector, workspace: workspace, integration_type: :database,
                                            default_analytics_db: true)
          expect(new_connector).to be_valid
        end
      end

      context "when creating an API connector" do
        it "is always valid regardless of default_analytics_db value" do
          new_connector = build(:connector, workspace: workspace, integration_type: :api, default_analytics_db: true)
          expect(new_connector).to be_valid
        end
      end
    end
  end

  describe "callbacks" do
    describe "#unset_other_default_analytics_dbs" do
      let(:workspace) { create(:workspace) }
      let!(:existing_default_connector) do
        create(:connector, workspace: workspace, integration_type: :database, default_analytics_db: true)
      end
      let!(:non_default_connector) do
        create(:connector, workspace: workspace, integration_type: :database, default_analytics_db: false)
      end

      it "unsets other default analytics DBs in the same workspace when setting a new default" do
        new_default_connector = create(:connector, workspace: workspace, integration_type: :database,
                                                   default_analytics_db: true)
        expect(existing_default_connector.reload.default_analytics_db).to be false
        expect(non_default_connector.reload.default_analytics_db).to be false
        expect(new_default_connector.default_analytics_db).to be true
      end

      it "does not affect connectors in other workspaces" do
        other_workspace = create(:workspace)
        other_workspace_connector = create(:connector, workspace: other_workspace, integration_type: :database,
                                                       default_analytics_db: true)

        create(:connector, workspace: workspace, integration_type: :database, default_analytics_db: true)

        expect(other_workspace_connector.reload.default_analytics_db).to be true
      end

      it "does not change anything if setting default_analytics_db to false" do
        new_connector = create(:connector, workspace: workspace, integration_type: :database,
                                           default_analytics_db: false)

        expect(existing_default_connector.reload.default_analytics_db).to be true
        expect(non_default_connector.reload.default_analytics_db).to be false
        expect(new_connector.default_analytics_db).to be false
      end
    end

    describe "#ensure_default_analytics_db_for_database_type" do
      let(:workspace) { create(:workspace) }

      it "sets default_analytics_db to true for the first database connector" do
        connector = create(:connector, workspace: workspace, integration_type: :database, default_analytics_db: true)
        expect(connector.default_analytics_db).to be true
      end

      it "does not set default_analytics_db to true for subsequent database connectors" do
        create(:connector, workspace: workspace, integration_type: :database)
        connector = create(:connector, workspace: workspace, integration_type: :database)
        expect(connector.default_analytics_db).to be false
      end

      it "always sets default_analytics_db to false for API connectors" do
        connector = create(:connector, workspace: workspace, integration_type: :api, default_analytics_db: true)
        expect(connector.default_analytics_db).to be false
      end
    end
  end

  describe "#icon_url" do
    it "returns the correct icon URL" do
      connector = build(:connector, connector_class_name: "TestConnector")
      expected_url = "https://raw.githubusercontent.com/polymetrics-ai/polymetrics/main/public/connector_icons/TestConnector.svg"
      expect(connector.icon_url).to eq(expected_url)
    end
  end

  describe "#fetch_schema" do
    let(:connector) { build(:connector, connector_class_name: "TestConnector", integration_type: :api) }
    let(:mock_schema) { { "stream1" => { "description" => "Test stream" } } }

    before do
      allow(Catalogs::FetchSchemaService).to receive(:new).and_return(double(call: mock_schema))
    end

    context "when integration type is database" do
      it "returns an empty array" do
        connector.integration_type = :database
        expect(connector.fetch_schema).to eq([])
      end
    end

    context "when integration type is api" do
      it "calls FetchSchemaService with connector class name" do
        expect(Catalogs::FetchSchemaService).to receive(:new).with("TestConnector")
        connector.fetch_schema
      end

      it "returns the schema from the service" do
        expect(connector.fetch_schema).to eq(mock_schema)
      end

      context "when service raises an error" do
        before do
          allow(Catalogs::FetchSchemaService).to receive(:new).and_raise(StandardError.new("Test error"))
        end

        it "returns an empty array and logs the error" do
          expect(Rails.logger).to receive(:error).with(/Error fetching schema for TestConnector: Test error/)
          expect(connector.fetch_schema).to eq([])
        end
      end
    end
  end

  describe "#available_streams" do
    let(:connector) { build(:connector) }
    let(:mock_schema) do
      {
        "stream1" => { "description" => "Test stream 1" },
        "stream2" => { "description" => "Test stream 2" }
      }
    end

    before do
      allow(connector).to receive(:fetch_schema).and_return(mock_schema)
    end

    it "returns array of stream names" do
      expect(connector.available_streams).to eq(%w[stream1 stream2])
    end
  end

  describe "#stream_descriptions" do
    let(:connector) { build(:connector) }
    let(:mock_schema) do
      {
        "stream1" => {
          "description" => "Test stream",
          "x-supported_sync_modes" => ["full_refresh"],
          "x-source_defined_primary_key" => ["id"],
          "required" => ["id"],
          "properties" => {
            "id" => { "type" => "integer" }
          }
        }
      }
    end

    before do
      allow(connector).to receive(:fetch_schema).and_return(mock_schema)
    end

    it "returns formatted stream descriptions" do
      expected_output = [
        {
          name: "stream1",
          description: "Test stream",
          sync_modes: ["full_refresh"],
          primary_key: ["id"],
          required_fields: ["id"],
          properties: {
            "id" => {
              type: "integer"
            }
          }
        }
      ]
      expect(connector.stream_descriptions).to eq(expected_output)
    end
  end
end
