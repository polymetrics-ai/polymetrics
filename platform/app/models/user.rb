# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  include DeviseTokenAuth::Concerns::User

  # Override sign_out to ensure proper token cleanup
  def sign_out(client)
    revoke_token(client)
    super
  end

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false, scope: :provider }

  has_many :user_organization_memberships, dependent: :destroy
  has_many :organizations, through: :user_organization_memberships
  has_many :user_workspace_memberships, dependent: :destroy
  has_many :workspaces, through: :user_workspace_memberships

  after_create :add_organization_to_user

  private

  def add_organization_to_user
    ActiveRecord::Base.transaction do
      organization = Organization.create!(name: organization_name)
      workspace = Workspace.create!(name: "default", organization: organization)
      user_organization_memberships.create!(organization: organization, role: "owner")
      user_workspace_memberships.create!(workspace: workspace, role: "owner")
    rescue ActiveRecord::RecordInvalid
      errors.add(:organization_name, "has already been taken")
    end

    raise ActiveRecord::Rollback if errors.any?
  end

  # Revokes the authentication token for the specified client
  # @param client [String] the client identifier
  # @return [Boolean] true if token was revoked successfully
  protected

  def revoke_token(client)
    return true if tokens.blank?

    tokens.delete(client)
    save!
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to revoke token: #{e.message}")
    false
  end
end
