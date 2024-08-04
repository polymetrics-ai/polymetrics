# frozen_string_literal: true

# spec/models/organization_spec.rb
require "rails_helper"

RSpec.describe Organization do
  subject { create(:organization) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:workspaces).dependent(:destroy) }
    it { is_expected.to have_many(:user_organization_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_organization_memberships) }
  end
end
