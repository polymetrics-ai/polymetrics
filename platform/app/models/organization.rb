# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :workspaces, dependent: :destroy
  has_many :user_organization_memberships, dependent: :destroy
  has_many :users, through: :user_organization_memberships

  validates :name, presence: true, uniqueness: true
end
