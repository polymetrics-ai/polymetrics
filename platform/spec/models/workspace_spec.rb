# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspace do
  describe "validations" do
    subject { build(:workspace) }

    it { is_expected.to validate_presence_of(:name) }

    it {
      expect(subject).to validate_uniqueness_of(:name)
        .scoped_to(:organization_id)
        .with_message(:unique_within_organization)
    }
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_many(:user_workspace_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_workspace_memberships) }
  end

  describe "uniqueness of name within organization" do
    let(:organization) { create(:organization) }
    let(:existing_workspace) { create(:workspace, organization:, name: "Test Workspace") }

    it "does not allow duplicate workspace names within the same organization" do
      existing_workspace # create the workspace
      new_workspace = build(:workspace, organization:, name: "Test Workspace")

      aggregate_failures do
        expect(new_workspace).not_to be_valid
        expect(new_workspace.errors[:name]).to include(
          I18n.t("activerecord.errors.models.workspace.attributes.name.unique_within_organization")
        )
      end
    end
  end
end
