# frozen_string_literal: true

RSpec.describe Syncs::CreateService do
  let(:connection) { create(:connection) }
  let(:service) { described_class.new(connection.id) }

  describe "#call" do
    let(:schema_data) do
      {
        "stream1" => {
          "name" => "stream1",
          "x-supported_sync_modes" => ["full_refresh", "incremental"],
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

    it "sets the correct attributes for each sync" do
      service.call
      syncs = connection.syncs.order(:stream_name)

      expect(syncs[0]).to have_attributes(
        stream_name: "stream1",
        sync_mode: "incremental_dedup",
        schedule_type: "manual",
        sync_frequency: "*/30 * * * *",
        supported_sync_modes: ["full_refresh", "incremental"],
        source_defined_cursor: true,
        default_cursor_field: ["updated_at"],
        source_defined_primary_key: ["id"]
      )

      expect(syncs[1]).to have_attributes(
        stream_name: "stream2",
        sync_mode: "full_refresh_overwrite",
        schedule_type: "manual",
        sync_frequency: "*/30 * * * *",
        supported_sync_modes: ["full_refresh"],
        source_defined_cursor: false
      )

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

    context "when determining sync mode" do
      context "with incremental sync mode support" do
        let(:schema_data) do
          {
            "incremental_stream" => {
              "name" => "incremental_stream",
              "x-supported_sync_modes" => ["incremental"],
              "x-default_sync_mode" => "incremental"
            }
          }
        end

        it "sets sync_mode to incremental_dedup" do
          service.call
          sync = connection.syncs.first
          expect(sync.sync_mode).to eq("incremental_dedup")
        end
      end

      context "with only full refresh support" do
        let(:schema_data) do
          {
            "full_refresh_stream" => {
              "name" => "full_refresh_stream",
              "x-supported_sync_modes" => ["full_refresh"],
              "x-default_sync_mode" => "full_refresh"
            }
          }
        end

        it "sets sync_mode to full_refresh_overwrite" do
          service.call
          sync = connection.syncs.first
          expect(sync.sync_mode).to eq("full_refresh_overwrite")
        end
      end

      context "with mixed sync mode support but non-incremental default" do
        let(:schema_data) do
          {
            "mixed_stream" => {
              "name" => "mixed_stream",
              "x-supported_sync_modes" => ["full_refresh", "incremental"],
              "x-default_sync_mode" => "full_refresh"
            }
          }
        end

        it "sets sync_mode to full_refresh_overwrite" do
          service.call
          sync = connection.syncs.first
          expect(sync.sync_mode).to eq("full_refresh_overwrite")
        end
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

    context "when connection is not found" do
      let(:service) { described_class.new(-1) }

      it "raises ActiveRecord::RecordNotFound" do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
