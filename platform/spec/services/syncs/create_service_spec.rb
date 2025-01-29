# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::CreateService do
  let(:workspace) { create(:workspace) }
  let(:source_connector) { create(:connector, workspace: workspace) }
  let(:destination_connector) { create(:connector, workspace: workspace, default_analytics_db: true) }
  let(:connection) { create(:connection, workspace: workspace, source: source_connector, destination: destination_connector) }
  let(:service) { described_class.new(connection.id) }

  let(:schema_data) do
    {
      "stream1" => {
        "name" => "stream1",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" },
          "email" => { "type" => "string" },
          "created_at" => { "type" => "string", "format" => "date-time" }
        },
        "x-supported_sync_modes" => %w[full_refresh incremental],
        "x-default_sync_mode" => "incremental",
        "x-source_defined_cursor" => true,
        "x-default_cursor_field" => ["updated_at"],
        "x-source_defined_primary_key" => ["id"]
      },
      "stream2" => {
        "name" => "stream2",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        },
        "x-supported_sync_modes" => ["full_refresh"],
        "x-default_sync_mode" => "full_refresh"
      },
      "stream3" => {
        "name" => "stream3",
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        },
        "x-supported_sync_modes" => ["incremental"],
        "x-default_sync_mode" => "incremental",
        "x-source_defined_cursor" => true,
        "x-default_cursor_field" => ["updated_at"]
      }
    }
  end

  before do
    allow_any_instance_of(Catalogs::FetchSchemaService)
      .to receive(:call)
      .and_return(schema_data)
  end

  describe "#call" do
    it "creates syncs for each stream" do
      expect { service.call }.to change(Sync, :count).by(3)
    end

    it "associates syncs with the connection" do
      service.call
      expect(connection.syncs.count).to eq(3)
    end

    describe "sync attributes" do
      before { service.call }

      let(:syncs) { connection.syncs.order(:stream_name) }

      it "sets correct attributes for stream1" do
        sync = syncs.find_by(stream_name: "stream1")
        expect(sync).to have_attributes(
          sync_mode: "incremental_dedup",
          schedule_type: "manual",
          sync_frequency: "*/30 * * * *",
          supported_sync_modes: %w[full_refresh incremental],
          source_defined_cursor: true,
          default_cursor_field: ["updated_at"],
          source_defined_primary_key: ["id"]
        )
      end

      it "sets correct attributes for stream2" do
        sync = syncs.find_by(stream_name: "stream2")
        expect(sync).to have_attributes(
          sync_mode: "full_refresh_overwrite",
          schedule_type: "manual",
          sync_frequency: "*/30 * * * *",
          supported_sync_modes: ["full_refresh"],
          source_defined_cursor: false
        )
      end

      it "sets correct attributes for stream3" do
        sync = syncs.find_by(stream_name: "stream3")
        expect(sync).to have_attributes(
          sync_mode: "incremental_dedup",
          schedule_type: "manual",
          sync_frequency: "*/30 * * * *",
          supported_sync_modes: ["incremental"],
          source_defined_cursor: true,
          default_cursor_field: ["updated_at"]
        )
      end
    end

    context "when schema fetch fails" do
      before do
        allow_any_instance_of(Catalogs::FetchSchemaService)
          .to receive(:call)
          .and_raise(StandardError.new("Failed to fetch schema"))
      end

      it "raises an error" do
        expect { service.call }.to raise_error(StandardError, "Failed to fetch schema")
      end

      it "does not create any syncs" do
        expect do
          service.call
        rescue StandardError
          nil
        end.not_to change(Sync, :count)
      end
    end

    context "when connection is invalid" do
      let(:service) { described_class.new(-1) }

      it "raises ActiveRecord::RecordNotFound" do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
