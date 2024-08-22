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

    describe "name uniqueness" do
      let(:workspace) { create(:workspace) }
      let!(:existing_connector) do
        create(:connector, workspace:, name: "Existing Connector", configuration: { key: "value" })
      end

      it "validates uniqueness of name scoped to workspace_id and configuration" do
        new_connector = build(:connector, workspace:, name: "Existing Connector",
                                          configuration: { key: "value" })
        expect(new_connector).not_to be_valid
        expect(new_connector.errors[:name]).to include("Existing Connector already exists for this workspace with the same configuration. Please change the name or configuration.")
      end

      it "allows same name with different configuration" do
        new_connector = build(:connector, workspace:, name: "Existing Connector",
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
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:connector_language).with_values(ruby: 0, python: 1, javascript: 2) }
  end

  describe "attributes" do
    it "has configuration as a jsonb column" do
      connector = create(:connector, configuration: { key: "value" })
      expect(connector.reload.configuration).to eq({ "key" => "value" })
    end
  end
end
