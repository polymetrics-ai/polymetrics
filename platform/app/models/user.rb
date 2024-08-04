# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  include DeviseTokenAuth::Concerns::User

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false, scope: :provider }

  has_many :user_organization_memberships, dependent: :destroy
  has_many :organizations, through: :user_organization_memberships
  has_many :user_workspace_memberships, dependent: :destroy
  has_many :workspaces, through: :user_workspace_memberships

  after_create :add_organization_to_user

  private

  def add_organization_to_user
    organization = Organization.create(name: organization_name)
    workspace = Workspace.create(name: "default", organization:)
    user_organization_memberships.create!(organization:, role: "owner")
    user_workspace_memberships.create!(workspace:, role: "owner")
  end
end
