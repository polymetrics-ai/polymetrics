# frozen_string_literal: true

RSpec.describe Syncs::CreateService do
  let(:connection) { create(:connection) }
  let(:service) { described_class.new(connection.id) }
  let(:mock_schema) do
    {
      stream1: { "name" => "stream1", "supported_sync_modes" => %w[full_refresh incremental] },
      stream2: { "name" => "stream2", "supported_sync_modes" => ["full_refresh"] }
    }
  end

  before do
    fetch_schema_service = instance_double(Catalogs::FetchSchemaService)
    allow(Catalogs::FetchSchemaService).to receive(:new).and_return(fetch_schema_service)
    allow(fetch_schema_service).to receive(:call).and_return(mock_schema)
  end

  describe "#call" do
    it "creates syncs for each stream in the schema" do
      expect { service.call }.to change(Sync, :count).by(2)
    end

    it "sets the correct attributes for each sync" do
      service.call
      syncs = connection.syncs.reload

      expect(syncs[0]).to have_attributes(
        stream_name: "stream1",
        sync_mode: "incremental_append",
        supported_sync_modes: %w[full_refresh incremental]
      )

      expect(syncs[1]).to have_attributes(
        stream_name: "stream2",
        sync_mode: "full_refresh_overwrite",
        supported_sync_modes: ["full_refresh"]
      )
    end
  end
end
