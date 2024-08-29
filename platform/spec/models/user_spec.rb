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
      let(:user) { build(:user, organization_name: "Test Org") }

      context "when organization name is unique" do
        it "creates an organization" do
          expect { user.save }.to change(Organization, :count).by(1)
        end

        it "creates a workspace" do
          expect { user.save }.to change(Workspace, :count).by(1)
        end

        it "creates user organization membership" do
          expect { user.save }.to change(UserOrganizationMembership, :count).by(1)
        end

        it "creates user workspace membership" do
          expect { user.save }.to change(UserWorkspaceMembership, :count).by(1)
        end

        it "sets the user as the owner of the organization" do
          user.save
          expect(user.user_organization_memberships.first.role).to eq("owner")
        end

        it "sets the user as the owner of the workspace" do
          user.save
          expect(user.user_workspace_memberships.first.role).to eq("owner")
        end
      end

      context "when organization name is not unique" do
        before do
          create(:organization, name: "Test Org")
        end

        it "does not create an organization" do
          expect { user.save }.not_to change(Organization, :count)
        end

        it "adds an error to the user" do
          user.save
          expect(user.errors[:organization_name]).to include("has already been taken")
        end

        it "does not create any associated records" do
          expect { user.save }.not_to change(Workspace, :count)
          expect { user.save }.not_to change(UserOrganizationMembership, :count)
          expect { user.save }.not_to change(UserWorkspaceMembership, :count)
        end
      end

      context "when organization_name is blank" do
        let(:user) { build(:user, organization_name: "") }

        it "does not create any records in the organizations table" do
          expect { user.save }.not_to change(Organization, :count)
        end

        it "does not create any records in the workspaces table" do
          expect { user.save }.not_to change(Workspace, :count)
        end

        it "does not create any records in the user_organization_memberships table" do
          expect { user.save }.not_to change(UserOrganizationMembership, :count)
        end

        it "does not create any records in the user_workspace_memberships table" do
          expect { user.save }.not_to change(UserWorkspaceMembership, :count)
        end
      end
    end
  end
end
