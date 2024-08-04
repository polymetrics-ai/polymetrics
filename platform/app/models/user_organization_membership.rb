# frozen_string_literal: true

class UserOrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }

  enum role: { member: "member", admin: "admin", owner: "owner" }
end
