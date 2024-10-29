# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectionBlueprint do
  let(:connection) { create(:connection) }
  let(:serialized_connection) { described_class.render_as_hash(connection) }

  it "includes the identifier" do
    expect(serialized_connection).to have_key(:id)
    expect(serialized_connection[:id]).to eq(connection.id)
  end

  it "includes basic fields" do
    expect(serialized_connection).to include(
      name: connection.name,
      status: connection.status,
      schedule_type: connection.schedule_type,
      sync_frequency: connection.sync_frequency,
      namespace: connection.namespace,
      stream_prefix: connection.stream_prefix,
      configuration: connection.configuration,
      created_at: connection.created_at,
      updated_at: connection.updated_at
    )
  end

  it "includes associated source connector" do
    expect(serialized_connection).to have_key(:source)
    expect(serialized_connection[:source]).to be_present
  end

  it "includes associated destination connector" do
    expect(serialized_connection).to have_key(:destination)
    expect(serialized_connection[:destination]).to be_present
  end

  it "includes associated syncs" do
    expect(serialized_connection).to have_key(:syncs)
    expect(serialized_connection[:syncs]).to be_an(Array)
  end
end
