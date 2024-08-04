# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive.scoped_to(:provider) }
  end

  describe "associations" do
    it { is_expected.to have_many(:user_organization_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:organizations).through(:user_organization_memberships) }
    it { is_expected.to have_many(:user_workspace_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:workspaces).through(:user_workspace_memberships) }
  end

  describe "devise modules" do
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
  end

  describe "callbacks" do
    describe "#add_organization_to_user" do
      let(:user) { create(:user, organization_name: "Test Org") }

      it "creates an organization after user creation" do
        expect { user.save }.to change(Organization, :count).by(1)
      end

      it "creates a default workspace for the organization" do
        expect { user.save }.to change(Workspace, :count).by(1)
      end

      it "creates user organization membership" do
        expect { user.save }.to change(UserOrganizationMembership, :count).by(1)
      end

      it "creates user workspace membership" do
        expect { user.save }.to change(UserWorkspaceMembership, :count).by(1)
      end

      it "sets the user as the owner of the organization and workspace" do
        expect(user.user_organization_memberships.first.role).to eq("owner")
        expect(user.user_workspace_memberships.first.role).to eq("owner")
      end
    end
  end
end
