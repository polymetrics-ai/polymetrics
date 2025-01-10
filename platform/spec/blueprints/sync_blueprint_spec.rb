# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncBlueprint do
  let(:sync) { create(:sync) }
  let(:serialized_sync) { described_class.render_as_hash(sync) }

  it "includes the identifier" do
    expect(serialized_sync).to have_key(:id)
    expect(serialized_sync[:id]).to eq(sync.id)
  end

  it "includes basic fields" do
    expect(serialized_sync).to include(
      stream_name: sync.stream_name,
      status: sync.status,
      sync_mode: sync.sync_mode,
      schedule_type: sync.schedule_type,
      sync_frequency: sync.sync_frequency,
      schema: sync.schema,
      supported_sync_modes: sync.supported_sync_modes,
      source_defined_cursor: sync.source_defined_cursor,
      default_cursor_field: sync.default_cursor_field,
      source_defined_primary_key: sync.source_defined_primary_key,
      destination_sync_mode: sync.destination_sync_mode,
      created_at: sync.created_at,
      updated_at: sync.updated_at
    )
  end

  context "when serializing a collection" do
    let(:syncs) { create_list(:sync, 3) }
    let(:serialized_syncs) { described_class.render_as_hash(syncs) }

    it "serializes all syncs" do
      expect(serialized_syncs).to be_an(Array)
      expect(serialized_syncs.length).to eq(3)
    end

    it "includes all required fields for each sync" do
      serialized_syncs.each do |sync_data|
        expect(sync_data.keys).to contain_exactly(
          :id, :stream_name, :status, :sync_mode, :schedule_type,
          :sync_frequency, :schema, :supported_sync_modes,
          :source_defined_cursor, :default_cursor_field,
          :source_defined_primary_key, :destination_sync_mode,
          :destination_database_schema,
          :created_at, :updated_at
        )
      end
    end
  end
end
