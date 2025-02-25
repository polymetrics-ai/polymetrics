# frozen_string_literal: true

class Sync < ApplicationRecord
  belongs_to :connection
  has_many :sync_runs, dependent: :destroy
  has_many :sync_read_records, dependent: :destroy

  enum status: { synced: 0, syncing: 1, queued: 2, error: 3, action_required: 4 }
  enum sync_mode: {
    full_refresh_overwrite: 0,
    full_refresh_append: 1,
    incremental_append: 2,
    incremental_dedup_history: 3,
    incremental_dedup: 4
  }
  enum schedule_type: { scheduled: 0, cron: 1, manual: 2 }

  validates :stream_name, presence: true, uniqueness: { scope: :connection_id }, length: { maximum: 255 }
  validates :status, presence: true
  validates :sync_mode, presence: true
  validates :schedule_type, presence: true
  validates :sync_frequency, presence: true, unless: :manual?

  def supports_incremental?
    supported_sync_modes.include?("incremental")
  end
end
