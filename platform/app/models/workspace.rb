# frozen_string_literal: true

class Workspace < ApplicationRecord
  belongs_to :organization
  has_many :user_workspace_memberships, dependent: :destroy
  has_many :users, through: :user_workspace_memberships
  has_many :connectors, dependent: :destroy
  has_many :connections, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :organization_id, message: :unique_within_organization }

  after_create :create_default_duckdb_connector

  def default_analytics_db
    connectors.find_by(default_analytics_db: true)
  end

  delegate :count, to: :connectors, prefix: true

  private

  def create_default_duckdb_connector
    Connectors::CreateDefaultAnalyticsDbService.new(self).call
  rescue StandardError => e
    Rails.logger.error("Failed to create default DuckDB connector: #{e.message}")
  end
end
