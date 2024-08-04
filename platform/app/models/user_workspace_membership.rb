# frozen_string_literal: true

class UserWorkspaceMembership < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :workspace_id }

  enum role: { member: "member", admin: "admin", owner: "owner" }
end
