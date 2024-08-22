# frozen_string_literal: true

require "rails_helper"

RSpec.describe Workspace do
  describe "validations" do
    subject(:workspace) { build(:workspace) }

    it { is_expected.to validate_presence_of(:name) }

    it {
      expect(workspace).to validate_uniqueness_of(:name)
        .scoped_to(:organization_id)
        .with_message(:unique_within_organization)
    }
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_many(:user_workspace_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_workspace_memberships) }
  end

  describe "uniqueness validation" do
    let(:organization) { create(:organization) }
    let(:existing_workspace_name) { "Existing Workspace" }

    before do
      create(:workspace, name: existing_workspace_name, organization:)
    end

    it "does not allow duplicate workspace names within the same organization" do
      new_workspace = build(:workspace, name: existing_workspace_name, organization:)
      expect(new_workspace).not_to be_valid
    end

    it "adds an error message for duplicate workspace names" do
      new_workspace = build(:workspace, name: existing_workspace_name, organization:)
      new_workspace.valid?
      expect(new_workspace.errors[:name]).to include("must be unique within the organization")
    end
  end
end
