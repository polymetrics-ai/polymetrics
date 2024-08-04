# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserWorkspaceMembership do
  describe "validations" do
    subject { create(:user_workspace_membership) }

    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:workspace_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:workspace) }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:role).with_values(member: "member", admin: "admin",
                                                            owner: "owner").backed_by_column_of_type(:string)
    }
  end
end
