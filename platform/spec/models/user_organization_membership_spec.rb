# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserOrganizationMembership do
  subject(:membership) { create(:user_organization_membership) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
  end

  describe "enums" do
    it {
      expect(membership).to define_enum_for(:role)
        .with_values(member: "member", admin: "admin", owner: "owner")
        .backed_by_column_of_type(:string)
    }
  end
end
