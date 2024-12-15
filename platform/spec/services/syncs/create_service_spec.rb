# frozen_string_literal: true

RSpec.describe Syncs::CreateService do
  let(:connection) { create(:connection) }
  let(:service) { described_class.new(connection.id) }

  describe "#call" do
    let(:schema_data) do
      {
        "stream1" => {
          "name" => "stream1",
          "x-supported_sync_modes" => %w[full_refresh incremental],
          "x-default_sync_mode" => "incremental",
          "x-source_defined_cursor" => true,
          "x-default_cursor_field" => ["updated_at"],
          "x-source_defined_primary_key" => ["id"]
        },
        "stream2" => {
          "name" => "stream2",
          "x-supported_sync_modes" => ["full_refresh"],
          "x-default_sync_mode" => "full_refresh"
        },
        "stream3" => {
          "name" => "stream3",
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

    it "creates syncs for each stream" do
      expect { service.call }.to change(Sync, :count).by(3)
    end

    describe "sync attributes" do
      before { service.call }

      let(:syncs) { connection.syncs.order(:stream_name) }

      it "sets correct attributes for stream1" do
        expect(syncs[0]).to have_attributes(
          stream_name: "stream1",
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
        expect(syncs[1]).to have_attributes(
          stream_name: "stream2",
          sync_mode: "full_refresh_overwrite",
          schedule_type: "manual",
          sync_frequency: "*/30 * * * *",
          supported_sync_modes: ["full_refresh"],
          source_defined_cursor: false
        )
      end

      it "sets correct attributes for stream3" do
        expect(syncs[2]).to have_attributes(
          stream_name: "stream3",
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
    end
  end
end
