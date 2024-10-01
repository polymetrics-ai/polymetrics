# frozen_string_literal: true

class Sync < ApplicationRecord
  belongs_to :connection
  has_many :sync_runs, dependent: :destroy

  enum status: { active: 0, inactive: 1, failed: 2 }
  enum sync_mode: {
    full_refresh_overwrite: 0,
    full_refresh_append: 1,
    incremental_append: 2,
    incremental_dedup_history: 3
  }

  validates :name, presence: true, uniqueness: { scope: :connection_id }
  validates :status, presence: true
  validates :sync_mode, presence: true
  validates :sync_frequency, presence: true

  serialize :schema, JSON
  serialize :supported_sync_modes, Array
  serialize :source_defined_cursor, :boolean
  serialize :default_cursor_field, Array
  serialize :source_defined_primary_key, Array
  serialize :destination_sync_mode, String

  def supports_incremental?
    supported_sync_modes.include?("incremental")
  end
end
