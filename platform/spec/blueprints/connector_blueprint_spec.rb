# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorBlueprint do
  let(:connector) { create(:connector) }
  let(:serialized_connector) { described_class.render_as_hash(connector) }

  it "includes the identifier" do
    expect(serialized_connector).to have_key(:id)
    expect(serialized_connector[:id]).to eq(connector.id)
  end

  it "includes basic fields" do
    expect(serialized_connector).to include(
      name: connector.name,
      connector_class_name: connector.connector_class_name,
      connector_language: connector.connector_language,
      integration_type: connector.integration_type,
      created_at: connector.created_at,
      updated_at: connector.updated_at,
      icon_url: connector.icon_url
    )
  end

  context "when serializing a collection" do
    let(:connectors) { create_list(:connector, 3) }
    let(:serialized_connectors) { described_class.render_as_hash(connectors) }

    it "serializes all connectors" do
      expect(serialized_connectors).to be_an(Array)
      expect(serialized_connectors.length).to eq(3)
    end

    it "includes all required fields for each connector" do
      serialized_connectors.each do |connector_data|
        expect(connector_data.keys).to contain_exactly(
          :id, :name, :connector_class_name, :connector_language,
          :integration_type, :created_at, :updated_at,
          :icon_url
        )
      end
    end
  end
end
