# frozen_string_literal: true

class Workspace < ApplicationRecord
  belongs_to :organization
  has_many :user_workspace_memberships, dependent: :destroy
  has_many :users, through: :user_workspace_memberships
  has_many :connectors, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :organization_id,
                                 message: :unique_within_organization }
end
